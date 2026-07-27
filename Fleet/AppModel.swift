import Foundation
import Combine

enum StatusFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case active = "活跃"
    case idle = "空闲"
    case expired = "疑似过期"

    var id: String { rawValue }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var sessions: [SessionRecord] = []
    @Published var statusFilter: StatusFilter = .all
    @Published var engineFilter: Engine?
    @Published var searchText: String = ""
    @Published private(set) var isLoading = false
    @Published private(set) var lastSyncedAt: Date?

    /// Cold scan of both engines, off the main thread. Fleet doesn't run a
    /// background process — this runs once per launch (see RootView), plus
    /// whenever the caller explicitly wants a fresh snapshot.
    func refresh() async {
        isLoading = true
        let scanned = await Task.detached(priority: .userInitiated) { () -> [SessionRecord] in
            ClaudeCodeScanner.scan() + CodexScanner.scan()
        }.value
        sessions = scanned.sorted { $0.lastActiveAt > $1.lastActiveAt }
        lastSyncedAt = Date()
        isLoading = false
    }

    var syncStatusDescription: String {
        guard let lastSyncedAt else { return "尚未同步" }
        return "上次同步 \(chineseRelativeTime(from: lastSyncedAt, isActive: false))"
    }

    var filteredSessions: [SessionRecord] {
        sessions.filter { session in
            let matchesStatus: Bool
            switch statusFilter {
            case .all: matchesStatus = true
            case .active: matchesStatus = session.status == .active
            case .idle: matchesStatus = session.status == .idle
            case .expired: matchesStatus = session.status == .expired
            }

            let matchesEngine = engineFilter == nil || session.engine == engineFilter

            let matchesSearch = searchText.isEmpty
                || session.displayName.localizedCaseInsensitiveContains(searchText)
                || session.projectPath.localizedCaseInsensitiveContains(searchText)

            return matchesStatus && matchesEngine && matchesSearch
        }
    }

    var activeSessions: [SessionRecord] {
        filteredSessions.filter { $0.status == .active }
    }

    var otherSessions: [SessionRecord] {
        filteredSessions.filter { $0.status != .active }
    }

    func count(for status: StatusFilter) -> Int {
        switch status {
        case .all: return sessions.count
        case .active: return sessions.filter { $0.status == .active }.count
        case .idle: return sessions.filter { $0.status == .idle }.count
        case .expired: return sessions.filter { $0.status == .expired }.count
        }
    }

    func count(for engine: Engine) -> Int {
        sessions.filter { $0.engine == engine }.count
    }

    /// Renames a session within Fleet only. Neither Claude Code nor Codex
    /// expose a safe way for an external tool to persist a display name back
    /// into their own session records (see session-tracker-需求文档.md 3.2),
    /// so this does not touch `~/.claude` or `~/.codex` — it only updates
    /// Fleet's own in-memory record.
    func rename(_ session: SessionRecord, to newName: String) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].displayName = newName
        NameStore.shared.setName(newName, for: session.id)
    }
}
