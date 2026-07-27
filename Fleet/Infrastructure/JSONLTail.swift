import Foundation

/// Reads small head/tail slices of a (potentially very large) JSONL file
/// without loading the whole file into memory — Claude Code session files
/// can be 17MB+/40k lines (see session-tracker-需求文档.md 4.1/5).
enum JSONLTail {
    static func headLines(of url: URL, maxLines: Int = 5, maxBytes: Int = 8192) -> [String] {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return [] }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: maxBytes),
              let text = String(data: data, encoding: .utf8) else { return [] }
        return text.split(separator: "\n", omittingEmptySubsequences: true)
            .prefix(maxLines)
            .map(String.init)
    }

    /// Lines from the last `maxBytes` of the file. The very first line in the
    /// result may be a truncated fragment (the seek offset can land mid-line)
    /// — callers should tolerate a failed parse on any single line rather
    /// than treat it as an error.
    static func tailLines(of url: URL, maxBytes: Int = 65_536) -> [String] {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return [] }
        defer { try? handle.close() }
        guard let size = try? handle.seekToEnd() else { return [] }
        let start = size > UInt64(maxBytes) ? size - UInt64(maxBytes) : 0
        try? handle.seek(toOffset: start)
        guard let data = try? handle.readToEnd(),
              let text = String(data: data, encoding: .utf8) else { return [] }
        return text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }
}
