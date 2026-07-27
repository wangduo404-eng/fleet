import SwiftUI

struct MainContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedSession: SessionRecord?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                searchField

                if !model.activeSessions.isEmpty {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(model.activeSessions) { session in
                            ActiveSessionCard(session: session)
                        }
                    }
                }

                if !model.otherSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("其他 SESSION")
                            .font(.system(size: 10.5))
                            .tracking(0.8)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 6)

                        VStack(spacing: 0) {
                            ForEach(Array(model.otherSessions.enumerated()), id: \.element.id) { index, session in
                                SessionListRow(session: session) {
                                    selectedSession = session
                                }
                                if index < model.otherSessions.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(item: $selectedSession) { session in
            let current = model.sessions.first(where: { $0.id == session.id }) ?? session
            SessionDetailView(session: current)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("正在运行的船队")
                    .font(FleetFont.brandTitle(27))
                Spacer()
                Text("\(model.activeSessions.count) / \(model.sessions.count) 艘")
                    .font(FleetFont.brandTitle(20))
                    .foregroundStyle(FleetColor.mint)
            }
            Text("上次同步 3 秒前 · 全部数据存储在本机")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索 session、项目或路径...", text: $model.searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.1))
        )
    }
}
