import SwiftUI

/// The user's own "worth keeping" list — sessions explicitly bookmarked
/// (via the bookmark icon on a card/row) before closing them, so finding
/// one again later doesn't depend on remembering an ID or guessing how
/// long ago it was closed (2026-07-27: replaces a "recently closed" time
/// window with an explicit, user-driven signal instead).
struct BookmarksView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedSession: SessionRecord?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header

                if model.bookmarkedSessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(model.bookmarkedSessions.enumerated()), id: \.element.id) { index, session in
                            SessionListRow(session: session) {
                                selectedSession = session
                            }
                            if index < model.bookmarkedSessions.count - 1 {
                                Divider()
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(item: $selectedSession) { session in
            let current = model.sessions.first(where: { $0.id == session.id }) ?? session
            SessionDetailView(session: current)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("书签")
                .font(FleetFont.brandTitle(35))
            Text("手动标记过、之后还想找回来的 session")
                .font(.system(size: 15.5))
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 11) {
            Image(systemName: "bookmark")
                .font(.system(size: 29))
                .foregroundStyle(.tertiary)
            Text("还没有书签")
                .font(.system(size: 17, weight: .medium))
            Text("在任意 session 上点书签图标，关掉终端后也能在这里找到它")
                .font(.system(size: 15.5))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
