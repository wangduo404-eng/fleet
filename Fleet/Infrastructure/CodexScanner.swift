import Foundation

/// Scans `~/.codex/sessions/**/rollout-*.jsonl` for session history.
///
/// `~/.codex/session_index.jsonl` is used only as a `thread_name` lookup —
/// it's an accelerator, not the source of truth. 2026-07-27 testing found
/// it can lag behind or miss sessions created via `codex exec`, so the
/// session list itself always comes from scanning the rollout files
/// directly. See session-tracker-需求文档.md 4.2 for the full research,
/// including the caveat that a brand-new session has no rollout file at all
/// until its first turn completes (sqlite state files exist before that,
/// but aren't useful for Fleet's purposes).
enum CodexScanner {
    static func scan() -> [SessionRecord] {
        let fm = FileManager.default
        let sessionsRoot = fm.homeDirectoryForCurrentUser.appending(path: ".codex/sessions")
        guard let enumerator = fm.enumerator(at: sessionsRoot, includingPropertiesForKeys: nil) else {
            return []
        }

        let threadNames = readThreadNames()
        let activeSessionIDs = currentlyActiveSessionIDs()

        var results: [SessionRecord] = []
        for case let url as URL in enumerator {
            guard url.lastPathComponent.hasPrefix("rollout-"), url.pathExtension == "jsonl" else { continue }
            if let record = parseSession(at: url, threadNames: threadNames, activeSessionIDs: activeSessionIDs) {
                results.append(record)
            }
        }
        return results
    }

    private static func readThreadNames() -> [String: String] {
        let fm = FileManager.default
        let indexURL = fm.homeDirectoryForCurrentUser.appending(path: ".codex/session_index.jsonl")
        guard let data = try? Data(contentsOf: indexURL),
              let text = String(data: data, encoding: .utf8) else { return [:] }
        var map: [String: String] = [:]
        for line in text.split(separator: "\n") {
            guard let lineData = String(line).data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let id = json["id"] as? String,
                  let name = json["thread_name"] as? String else { continue }
            map[id] = name
        }
        return map
    }

    /// Resolves to the *root* session id currently being worked on by each
    /// live Codex CLI process — not a set of file paths. Filters out
    /// OpenAI's ChatGPT desktop app, which bundles its own unrelated
    /// `codex`-named sandbox helper binaries — a real pitfall hit during
    /// testing, not a hypothetical one.
    ///
    /// A single Codex process can have many rollout files open at once: one
    /// per subagent it has spawned, alongside the root conversation file
    /// (real-machine testing 2026-07-28: 207 of 290 rollout files on this
    /// machine are subagent threads, not user-facing sessions). All of them
    /// share the same `session_meta.payload.session_id` — the root's id —
    /// even though each subagent file's own `payload.id` differs. Picking
    /// "whichever open file has the latest mtime" and treating *that file's
    /// own path* as the active identity (the original approach) breaks as
    /// soon as a subagent file happens to be the most recently written one:
    /// the session shown as active ends up being that tiny subagent
    /// snippet — wrong turn count, wrong context usage — instead of the
    /// actual root conversation the user is watching. Resolving to the
    /// *session id* first (root id for both root and subagent files) fixes
    /// this: activity from any of a process's open files, root or subagent,
    /// correctly marks the root session as active.
    private static func currentlyActiveSessionIDs() -> Set<String> {
        let candidates = ProcessInspector.runningProcesses().filter { proc in
            let exePath = proc.command.split(separator: " ").first.map(String.init) ?? proc.command
            return exePath.hasSuffix("/bin/codex") && !exePath.contains("/ChatGPT.app/")
        }
        let fm = FileManager.default
        var ids: Set<String> = []
        for candidate in candidates {
            let open = ProcessInspector.openFilePaths(pid: candidate.pid)
                .filter { $0.contains("/.codex/sessions/") && $0.hasSuffix(".jsonl") }

            // Among a process's currently-open rollout files, only the most
            // recently modified one reflects what it's actually doing right
            // now (older open files can be stale fds left over from a prior
            // session switch — see 2026-07-27 finding above).
            guard let latest = open.max(by: { mtime(of: $0, fm) < mtime(of: $1, fm) }),
                  let sessionID = resolvedSessionID(at: URL(fileURLWithPath: latest)) else { continue }
            ids.insert(sessionID)
        }
        return ids
    }

    private static func mtime(of path: String, _ fm: FileManager) -> Date {
        guard let attributes = try? fm.attributesOfItem(atPath: path) else { return .distantPast }
        return attributes[.modificationDate] as? Date ?? .distantPast
    }

    private static func resolvedSessionID(at url: URL) -> String? {
        let headLines = JSONLTail.headLines(of: url, maxLines: 3, maxBytes: 262_144)
        guard let meta = firstJSON(in: headLines, whereType: "session_meta"),
              let payload = meta["payload"] as? [String: Any] else { return nil }
        return (payload["session_id"] as? String) ?? (payload["id"] as? String)
    }

    private static func parseSession(at url: URL, threadNames: [String: String], activeSessionIDs: Set<String>) -> SessionRecord? {
        // `session_meta`'s line embeds the full system prompt
        // (`base_instructions.text`), which alone runs 15-22KB on a regular
        // interactive session — comfortably over a "small head read" budget.
        // A default 8KB budget silently truncated that line mid-JSON, so
        // parsing failed and every regular session got dropped; only
        // subagent-type sessions (a much shorter session_meta line) survived.
        // Found via real-machine testing 2026-07-27, not a hypothetical.
        let headLines = JSONLTail.headLines(of: url, maxLines: 3, maxBytes: 262_144)
        guard let meta = firstJSON(in: headLines, whereType: "session_meta"),
              let payload = meta["payload"] as? [String: Any],
              let sessionID = (payload["session_id"] as? String) ?? (payload["id"] as? String),
              let cwd = payload["cwd"] as? String else { return nil }

        // Subagent threads (spawned automatically by Codex's own multi-agent
        // orchestration, not something the user directly runs or resumes)
        // share the root's session_id, so without this they'd show up as
        // extra cards/rows carrying the *root's* id — a duplicate-id
        // collision, not a distinct session. Skip them; the root file
        // already represents this session on its own.
        if payload["thread_source"] as? String == "subagent" { return nil }

        let isActive = activeSessionIDs.contains(sessionID)
        let fm = FileManager.default
        let attributes = try? fm.attributesOfItem(atPath: url.path)
        let sizeBytes = (attributes?[.size] as? Int64) ?? Int64((attributes?[.size] as? Int) ?? 0)
        let mtime = (attributes?[.modificationDate] as? Date) ?? Date()

        let contextUsage = lastTokenUsage(in: JSONLTail.tailLines(of: url))
        let originator = payload["originator"] as? String
        let origin: SessionOrigin = originator == "Codex Desktop" ? .desktopApp : .terminal
        let turnCount = JSONLTail.occurrenceCount(of: "\"type\":\"task_complete\"", in: url)

        return SessionRecord(
            id: sessionID,
            engine: .codex,
            origin: origin,
            displayName: NameStore.shared.name(for: sessionID)
                ?? threadNames[sessionID]
                ?? ScannerSupport.fallbackName(projectPath: cwd, id: sessionID),
            projectPath: ScannerSupport.shortenedPath(cwd),
            isActive: isActive,
            lastActiveAt: mtime,
            fileSizeBytes: sizeBytes,
            contextUsage: contextUsage,
            turnCount: turnCount,
            resumeCommand: "codex resume \(sessionID)",
            isBookmarked: BookmarkStore.shared.isBookmarked(sessionID)
        )
    }

    private static func firstJSON(in lines: [String], whereType type: String) -> [String: Any]? {
        for line in lines {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["type"] as? String == type else { continue }
            return json
        }
        return nil
    }

    /// Parses a `token_count` event. Verified against a real captured sample
    /// (2026-07-28): the line's top-level `type` is `event_msg`, not
    /// `token_count` — that lives one level down at `payload.type`. And the
    /// usage numbers are nested one level deeper still, under
    /// `payload.info`, not directly on `payload`. The original guess (both
    /// checked directly on `payload`) never matched anything on real data,
    /// which is why Codex cards always showed "暂无数据".
    private static func lastTokenUsage(in lines: [String]) -> ContextUsage? {
        for line in lines.reversed() {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["type"] as? String == "event_msg",
                  let payload = json["payload"] as? [String: Any],
                  payload["type"] as? String == "token_count",
                  let info = payload["info"] as? [String: Any] else { continue }

            let windowTokens = info["model_context_window"] as? Int
            if let used = extractTokenCount(info["last_token_usage"])
                ?? extractTokenCount(info["total_token_usage"]) {
                return ContextUsage(usedTokens: used, windowTokens: windowTokens)
            }
        }
        return nil
    }

    private static func extractTokenCount(_ value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        guard let dict = value as? [String: Any] else { return nil }
        if let total = dict["total_tokens"] as? Int { return total }
        let input = dict["input_tokens"] as? Int ?? 0
        let output = dict["output_tokens"] as? Int ?? 0
        let cached = dict["cached_input_tokens"] as? Int ?? 0
        let sum = input + output + cached
        return sum > 0 ? sum : nil
    }
}
