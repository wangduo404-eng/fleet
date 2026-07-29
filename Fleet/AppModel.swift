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

/// Home is a fixed "smart view" (à la Things' Today / Linear's Inbox) — not
/// just the status filter set to `.active`. Selecting any row under
/// "浏览全部 Session" switches into Browse so the sidebar never shows two
/// contradictory selections at once (2026-07-27 design feedback).
enum ViewMode {
    case home
    case bookmarks
    case browse
}

enum UpdateInstallState: Equatable {
    case idle
    case inProgress(String)
    case failed(String)
}

@MainActor
final class AppModel: ObservableObject {
    @Published var sessions: [SessionRecord] = []
    @Published var viewMode: ViewMode = .home
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
    @Published private(set) var availableUpdate: AvailableUpdate?
    @Published private(set) var updateInstallState: UpdateInstallState = .idle

    private static let firstLaunchAcknowledgedKey = "hasAcknowledgedFirstLaunchNotice"

    /// Whether the one-time "here's what this reads" notice has been shown
    /// and dismissed — gates the very first scan (see RootView), so a new
    /// user sees it before their session history appears, not after.
    @Published private(set) var hasAcknowledgedFirstLaunch =
        UserDefaults.standard.bool(forKey: AppModel.firstLaunchAcknowledgedKey)

    func acknowledgeFirstLaunch() {
        hasAcknowledgedFirstLaunch = true
        UserDefaults.standard.set(true, forKey: AppModel.firstLaunchAcknowledgedKey)
    }

    /// Once per launch is enough — this is a convenience nudge, not
    /// something that needs to notice a new release within seconds, and
    /// GitHub's unauthenticated API is rate-limited per IP.
    func checkForUpdate() async {
        availableUpdate = await UpdateChecker.checkForUpdate()
    }

    func installAvailableUpdate() async {
        guard let update = availableUpdate else { return }
        let result = await UpdateInstaller.downloadAndInstall(update) { [weak self] status in
            Task { @MainActor in self?.updateInstallState = .inProgress(status) }
        }
        if case .failure = result {
            updateInstallState = .failed("更新失败，可以手动去 GitHub 下载安装")
        }
    }

    /// Cold scan of both engines, off the main thread. Fleet doesn't run a
    /// background process — this runs once per launch (see RootView), plus
    /// whenever the caller explicitly wants a fresh snapshot.
    func refresh() async {
        // The window-activation trigger fires on every status-item click —
        // rapid repeated clicks (observed in practice) shouldn't stack up
        // concurrent scans.
        guard !isLoading else { return }
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

    /// Home's criteria is fixed (active + terminal-origin), independent of
    /// whatever the user has set under "浏览全部 Session" — it's a distinct
    /// smart view, not a saved filter combination.
    private var homeSessions: [SessionRecord] {
        sessions.filter { $0.isActive && $0.origin == .terminal }
    }

    var homeClaudeSessions: [SessionRecord] {
        homeSessions.filter { $0.engine == .claudeCode }
    }

    var homeCodexSessions: [SessionRecord] {
        homeSessions.filter { $0.engine == .codex }
    }

    /// Sessions the user explicitly marked as "I'll want this again" —
    /// unlike Home, not restricted to active/terminal-origin, since the
    /// whole point is finding something again *after* it's no longer
    /// running (2026-07-27: bookmarking replaces guessing a "recently
    /// closed" time window).
    var bookmarkedSessions: [SessionRecord] {
        sessions.filter { $0.isBookmarked }.sorted { $0.lastActiveAt > $1.lastActiveAt }
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
    /// into their own session records, so this does not touch `~/.claude` or
    /// `~/.codex` — it only updates Fleet's own in-memory record.
    func rename(_ session: SessionRecord, to newName: String) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].displayName = newName
        NameStore.shared.setName(newName, for: session.id)
    }

    /// Bookmarking is Fleet's own overlay, same as rename — it never
    /// touches `~/.claude` or `~/.codex`.
    func toggleBookmark(_ session: SessionRecord) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        let newValue = !sessions[index].isBookmarked
        sessions[index].isBookmarked = newValue
        BookmarkStore.shared.setBookmarked(newValue, for: session.id)
    }
}
