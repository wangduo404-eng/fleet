import SwiftUI

/// The default landing view — a fixed smart view (see AppModel.ViewMode),
/// not a saved filter. Only currently-running terminal sessions, split into
/// a Claude Code column and a Codex column so "which engine is this" reads
/// at a glance instead of being inferred from a color swatch on a mixed,
/// recency-sorted grid. No search here — with 2-4 cards, there's nothing to
/// search for; that lives in Browse. (2026-07-27 design feedback.)
struct HomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                HStack(alignment: .top, spacing: 20) {
                    engineColumn(title: "Claude Code", accent: FleetColor.claudeAccent, sessions: model.homeClaudeSessions)
                    engineColumn(title: "Codex", accent: FleetColor.codexAccent, sessions: model.homeCodexSessions)
                }

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("正在运行的船队")
                    .font(FleetFont.brandTitle(27))
                Spacer()
                Text("\(model.homeClaudeSessions.count + model.homeCodexSessions.count) 艘")
                    .font(FleetFont.brandTitle(20))
                    .foregroundStyle(FleetColor.mint)
            }
            Text("\(model.syncStatusDescription) · 只显示当前活跃的 session")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private func engineColumn(title: String, accent: Color, sessions: [SessionRecord]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(accent)
                    .frame(width: 11, height: 11)
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                Text("\(sessions.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if sessions.isEmpty {
                emptyPlaceholder
            } else {
                VStack(spacing: 12) {
                    ForEach(sessions) { session in
                        ActiveSessionCard(session: session)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color.primary.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .frame(height: 90)
            .overlay(
                Text("当前没有运行中的 session")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
            )
    }
}
