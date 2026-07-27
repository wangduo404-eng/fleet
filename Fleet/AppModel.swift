import Foundation
import Combine
import SwiftUI

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
    // Defaults to hiding "Codex Desktop" (the ChatGPT desktop app's own
    // Codex feature) — the user's actual intent was monitoring their own
    // terminal, and on this machine 67% of Codex session files turned out
    // to be Desktop-app automation, not terminal activity (2026-07-27).
    @Published var originFilter: SessionOrigin? = .terminal
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

        // Populating ~245 rows in one shot (empty -> full) let SwiftUI's
        // default implicit animation leave a stale frame on screen — a
        // ghost card briefly overlapping the real one until the next redraw
        // (observed in practice: gone as soon as the window took focus
        // again). Disabling animation for this specific assignment avoids
        // that cross-fade entirely instead of relying on "look away and
        // back" to self-heal it.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            sessions = scanned.sorted { $0.lastActiveAt > $1.lastActiveAt }
        }
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
            let matchesOrigin = originFilter == nil || session.origin == originFilter

            let matchesSearch = searchText.isEmpty
                || session.displayName.localizedCaseInsensitiveContains(searchText)
                || session.projectPath.localizedCaseInsensitiveContains(searchText)

            return matchesStatus && matchesEngine && matchesOrigin && matchesSearch
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

    func count(for origin: SessionOrigin) -> Int {
        sessions.filter { $0.origin == origin }.count
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
