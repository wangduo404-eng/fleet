import Foundation

/// Scans `~/.claude/projects/**/*.jsonl` for session history, and
/// `~/.claude/sessions/*.json` for the currently-active-process registry.
/// See session-tracker-需求文档.md 4.1/4.2 for the underlying research.
enum ClaudeCodeScanner {
    static func scan() -> [SessionRecord] {
        let fm = FileManager.default
        let projectsRoot = fm.homeDirectoryForCurrentUser.appending(path: ".claude/projects")
        guard let projectDirs = try? fm.contentsOfDirectory(at: projectsRoot, includingPropertiesForKeys: nil) else {
            return []
        }

        let activePIDs = readActiveRegistry()

        var results: [SessionRecord] = []
        for projectDir in projectDirs {
            guard let files = try? fm.contentsOfDirectory(at: projectDir, includingPropertiesForKeys: nil) else { continue }
            for file in files where file.pathExtension == "jsonl" {
                if let record = parseSession(at: file, activePIDs: activePIDs) {
                    results.append(record)
                }
            }
        }
        return results
    }

    /// `~/.claude/sessions/<pid>.json` holds `{pid, sessionId, cwd, status,
    /// name, updatedAt}` for live processes, but per the requirements doc we
    /// don't fully trust "file exists" as "process alive" — re-verify with
    /// `kill(pid, 0)`.
    private static func readActiveRegistry() -> Set<String> {
        let fm = FileManager.default
        let sessionsDir = fm.homeDirectoryForCurrentUser.appending(path: ".claude/sessions")
        guard let files = try? fm.contentsOfDirectory(at: sessionsDir, includingPropertiesForKeys: nil) else {
            return []
        }
        var activeSessionIDs: Set<String> = []
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let sessionID = json["sessionId"] as? String,
                  let pid = json["pid"] as? Int,
                  ProcessInspector.isAlive(pid: Int32(pid)) else { continue }
            activeSessionIDs.insert(sessionID)
        }
        return activeSessionIDs
    }

    private static func parseSession(at url: URL, activePIDs: Set<String>) -> SessionRecord? {
        let sessionID = url.deletingPathExtension().lastPathComponent
        let headLines = JSONLTail.headLines(of: url)
        guard let cwd = firstStringValue(in: headLines, key: "cwd") else { return nil }

        let fm = FileManager.default
        let attributes = try? fm.attributesOfItem(atPath: url.path)
        let sizeBytes = (attributes?[.size] as? Int64) ?? Int64((attributes?[.size] as? Int) ?? 0)
        let mtime = (attributes?[.modificationDate] as? Date) ?? Date()

        let contextUsage = lastAssistantUsage(in: JSONLTail.tailLines(of: url))

        return SessionRecord(
            id: sessionID,
            engine: .claudeCode,
            displayName: NameStore.shared.name(for: sessionID)
                ?? ScannerSupport.fallbackName(projectPath: cwd, id: sessionID),
            projectPath: ScannerSupport.shortenedPath(cwd),
            isActive: activePIDs.contains(sessionID),
            lastActiveAt: mtime,
            fileSizeBytes: sizeBytes,
            contextUsage: contextUsage,
            resumeCommand: "claude --resume \(sessionID)"
        )
    }

    private static func firstStringValue(in lines: [String], key: String) -> String? {
        for line in lines {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let value = json[key] as? String else { continue }
            return value
        }
        return nil
    }

    /// Approximate current context size from the most recent assistant
    /// turn's `message.usage`. Claude Code's session files don't record the
    /// model's context window limit, so `windowTokens` is always nil here.
    private static func lastAssistantUsage(in lines: [String]) -> ContextUsage? {
        for line in lines.reversed() {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["type"] as? String == "assistant",
                  let message = json["message"] as? [String: Any],
                  let usage = message["usage"] as? [String: Any] else { continue }
            let input = usage["input_tokens"] as? Int ?? 0
            let cacheCreate = usage["cache_creation_input_tokens"] as? Int ?? 0
            let cacheRead = usage["cache_read_input_tokens"] as? Int ?? 0
            let used = input + cacheCreate + cacheRead
            guard used > 0 else { continue }
            return ContextUsage(usedTokens: used, windowTokens: nil)
        }
        return nil
    }
}
