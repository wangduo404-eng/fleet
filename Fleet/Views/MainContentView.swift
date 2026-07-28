import SwiftUI

struct MainContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedSession: SessionRecord?
    @State private var showOlderSessions = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    // Searching implies looking for something specific regardless of age,
    // so the age-based fold only applies when there's no active search.
    private var recentOtherSessions: [SessionRecord] {
        model.searchText.isEmpty ? model.otherSessions.filter { !$0.isLongUnused } : model.otherSessions
    }

    private var olderOtherSessions: [SessionRecord] {
        model.searchText.isEmpty ? model.otherSessions.filter { $0.isLongUnused } : []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header

                searchField

                if !model.activeSessions.isEmpty {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(model.activeSessions) { session in
                            ActiveSessionCard(session: session)
                        }
                    }
                }

                if !recentOtherSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("其他 SESSION")
                            .font(.system(size: 13.5))
                            .tracking(1)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)

                        sessionRows(recentOtherSessions)
                    }
                }

                if !olderOtherSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            showOlderSessions.toggle()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: showOlderSessions ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("一个月前的 SESSION（\(olderOtherSessions.count)）")
                                    .font(.system(size: 13.5))
                                    .tracking(1)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)

                        if showOlderSessions {
                            sessionRows(olderOtherSessions)
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
            HStack(alignment: .firstTextBaseline) {
                Text("正在航行的船队")
                    .font(FleetFont.brandTitle(35))
                Spacer()
                Text("\(model.activeSessions.count) / \(model.sessions.count) 艘")
                    .font(FleetFont.brandTitle(26))
                    .foregroundStyle(FleetColor.mint)
            }
            Text("\(model.syncStatusDescription) · 全部数据存储在本机")
                .font(.system(size: 15.5))
                .foregroundStyle(.secondary)
        }
    }

    private func sessionRows(_ sessions: [SessionRecord]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                SessionListRow(session: session) {
                    selectedSession = session
                }
                if index < sessions.count - 1 {
                    Divider()
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索 session、项目或路径...", text: $model.searchText)
                .textFieldStyle(.plain)
        }
        .font(.system(size: 15))
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.1))
        )
    }
}
