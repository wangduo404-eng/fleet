import Foundation

/// Fleet's own bookmark list — session_ids the user explicitly marked as
/// "I'll want this again," independent of whether the session is still
/// active. Same pattern and storage location as NameStore: this is Fleet's
/// own overlay, never written into `~/.claude` or `~/.codex`.
final class BookmarkStore: @unchecked Sendable {
    static let shared = BookmarkStore()

    private let url: URL
    private var bookmarked: Set<String>
    private let lock = NSLock()

    init(url: URL = BookmarkStore.defaultURL) {
        self.url = url
        self.bookmarked = (try? JSONDecoder().decode(Set<String>.self, from: Data(contentsOf: url))) ?? []
    }

    static var defaultURL: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appending(path: "Library/Application Support/Fleet/bookmarks.json")
    }

    func isBookmarked(_ sessionID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return bookmarked.contains(sessionID)
    }

    func setBookmarked(_ isBookmarked: Bool, for sessionID: String) {
        lock.lock()
        if isBookmarked {
            bookmarked.insert(sessionID)
        } else {
            bookmarked.remove(sessionID)
        }
        let snapshot = bookmarked
        lock.unlock()
        persist(snapshot)
    }

    private func persist(_ snapshot: Set<String>) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }
}
