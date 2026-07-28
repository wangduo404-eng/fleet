import Foundation

/// Reads small head/tail slices of a (potentially very large) JSONL file
/// without loading the whole file into memory — Claude Code session files
/// can be 17MB+/40k lines.
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

    /// Counts occurrences of a literal byte marker across the whole file,
    /// reading in fixed-size chunks rather than loading the file into memory
    /// — needed because turn/task markers can appear anywhere in the file,
    /// not just the head/tail, and Codex rollout files can exceed 100MB.
    /// A `(marker.count - 1)`-byte carry across chunk boundaries catches
    /// matches split by a chunk edge without double-counting (any match
    /// fully contained in one chunk is already found by that chunk's own
    /// search, and the carry — missing that match's first byte — can't
    /// rediscover it).
    static func occurrenceCount(of marker: String, in url: URL, chunkSize: Int = 1_048_576) -> Int {
        guard let markerData = marker.data(using: .utf8), !markerData.isEmpty,
              let handle = try? FileHandle(forReadingFrom: url) else { return 0 }
        defer { try? handle.close() }

        var count = 0
        var carry = Data()
        while let chunk = try? handle.read(upToCount: chunkSize), !chunk.isEmpty {
            var buffer = carry
            buffer.append(chunk)

            var searchStart = buffer.startIndex
            while let range = buffer.range(of: markerData, in: searchStart..<buffer.endIndex) {
                count += 1
                searchStart = range.upperBound
            }

            carry = buffer.suffix(markerData.count - 1)
        }
        return count
    }
}
