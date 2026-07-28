import Foundation

/// Fleet's own session_id -> custom display name mapping. Neither Claude
/// Code nor Codex expose a safe way for an external tool to persist a name
/// back into their own session records, so this overlay lives entirely in
/// Fleet's own file and never touches `~/.claude` or `~/.codex`.
final class NameStore: @unchecked Sendable {
    static let shared = NameStore()

    private let url: URL
    private var names: [String: String]
    private let lock = NSLock()

    init(url: URL = NameStore.defaultURL) {
        self.url = url
        self.names = (try? JSONDecoder().decode([String: String].self, from: Data(contentsOf: url))) ?? [:]
    }

    static var defaultURL: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appending(path: "Library/Application Support/Fleet/session-names.json")
    }

    func name(for sessionID: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return names[sessionID]
    }

    func setName(_ name: String, for sessionID: String) {
        lock.lock()
        names[sessionID] = name
        let snapshot = names
        lock.unlock()
        persist(snapshot)
    }

    private func persist(_ snapshot: [String: String]) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }
}
