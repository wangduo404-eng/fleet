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
        let activeRolloutPaths = currentlyOpenRolloutPaths()

        var results: [SessionRecord] = []
        for case let url as URL in enumerator {
            guard url.lastPathComponent.hasPrefix("rollout-"), url.pathExtension == "jsonl" else { continue }
            let isActive = activeRolloutPaths.contains(url.standardizedFileURL.path)
            if let record = parseSession(at: url, threadNames: threadNames, isActive: isActive) {
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

    /// Rollout files that reflect what the user is actually working in right
    /// now, one per live Codex CLI process. Filters out OpenAI's ChatGPT
    /// desktop app, which bundles its own unrelated `codex`-named sandbox
    /// helper binaries — a real pitfall hit during testing, not a
    /// hypothetical one.
    private static func currentlyOpenRolloutPaths() -> Set<String> {
        let candidates = ProcessInspector.runningProcesses().filter { proc in
            let exePath = proc.command.split(separator: " ").first.map(String.init) ?? proc.command
            return exePath.hasSuffix("/bin/codex") && !exePath.contains("/ChatGPT.app/")
        }
        let fm = FileManager.default
        var paths: Set<String> = []
        for candidate in candidates {
            let open = ProcessInspector.openFilePaths(pid: candidate.pid)
                .filter { $0.contains("/.codex/sessions/") && $0.hasSuffix(".jsonl") }

            // A single process can hold more than one rollout file open at
            // once — observed in real testing (2026-07-27): a long-running
            // codex process kept an old, no-longer-written rollout file open
            // alongside the one it's actually using, and counting both
            // inflated the active count (4 shown vs. 3 real sessions).
            // Only the most recently modified file is what's actually live.
            guard let latest = open.max(by: { mtime(of: $0, fm) < mtime(of: $1, fm) }) else { continue }
            paths.insert(latest)
        }
        return paths
    }

    private static func mtime(of path: String, _ fm: FileManager) -> Date {
        guard let attributes = try? fm.attributesOfItem(atPath: path) else { return .distantPast }
        return attributes[.modificationDate] as? Date ?? .distantPast
    }

    private static func parseSession(at url: URL, threadNames: [String: String], isActive: Bool) -> SessionRecord? {
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

        let fm = FileManager.default
        let attributes = try? fm.attributesOfItem(atPath: url.path)
        let sizeBytes = (attributes?[.size] as? Int64) ?? Int64((attributes?[.size] as? Int) ?? 0)
        let mtime = (attributes?[.modificationDate] as? Date) ?? Date()

        let contextUsage = lastTokenUsage(in: JSONLTail.tailLines(of: url))

        return SessionRecord(
            id: sessionID,
            engine: .codex,
            displayName: NameStore.shared.name(for: sessionID)
                ?? threadNames[sessionID]
                ?? ScannerSupport.fallbackName(projectPath: cwd, id: sessionID),
            projectPath: ScannerSupport.shortenedPath(cwd),
            isActive: isActive,
            lastActiveAt: mtime,
            fileSizeBytes: sizeBytes,
            contextUsage: contextUsage,
            resumeCommand: "codex resume \(sessionID)"
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

    /// Best-effort parse of a `token_count` event. The exact shape of
    /// `total_token_usage` / `last_token_usage` wasn't verified against a
    /// captured real sample (see session-tracker-需求文档.md 4.1) — this
    /// tries a couple of plausible shapes and degrades to nil rather than
    /// risk showing a wrong number.
    private static func lastTokenUsage(in lines: [String]) -> ContextUsage? {
        for line in lines.reversed() {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["type"] as? String == "token_count",
                  let payload = json["payload"] as? [String: Any] else { continue }

            let windowTokens = payload["model_context_window"] as? Int
            if let used = extractTokenCount(payload["last_token_usage"])
                ?? extractTokenCount(payload["total_token_usage"]) {
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
