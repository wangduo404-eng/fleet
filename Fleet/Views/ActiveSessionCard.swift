import SwiftUI

struct ActiveSessionCard: View {
    let session: SessionRecord
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: engine identity is a labeled badge, not just a small
            // icon — that plus a bigger name below gives the card a clear
            // focal point (2026-07-28 feedback). Status/time on its own row
            // avoids cramming badge + time + bookmark into one row, which
            // forced "Claude Code" to wrap mid-word at this font size.
            HStack(spacing: 8) {
                engineBadge
                Spacer()
                BookmarkButton(session: session, size: 16)
                    .foregroundStyle(textColor.opacity(session.isBookmarked ? 0.85 : 0.32))
            }

            HStack(spacing: 5) {
                Circle()
                    .fill(FleetColor.mint)
                    .frame(width: 7, height: 7)
                Text(session.lastActiveDescription)
                    .font(.system(size: 13))
            }
            .foregroundStyle(textColor.opacity(0.55))
            .padding(.top, 5)

            EditableNameLabel(
                name: session.displayName,
                font: .system(size: 22, weight: .semibold),
                textColor: textColor.opacity(0.95)
            ) { newName in
                model.rename(session, to: newName)
            }
            .padding(.top, 7)

            // Project path was dropped earlier when the name alone seemed
            // to say enough, but a fallback name like "yafo · 6d39dd8f"
            // doesn't actually say which project — bringing it back so the
            // card is a complete picture on its own (2026-07-28 feedback).
            Text(session.projectPath)
                .font(FleetFont.mono(15))
                .foregroundStyle(textColor.opacity(0.5))
                .padding(.top, 2)
                .lineLimit(1)
                .truncationMode(.middle)

            statRow
                .padding(.top, 10)

            Spacer(minLength: 6)

            HStack(spacing: 11) {
                Button("复制命令") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(session.resumeCommand, forType: .string)
                }
                .buttonStyle(.bordered)

                // A session on this card is, by definition, already running
                // — "resume" doesn't mean anything for it, so it's disabled
                // rather than a live no-op button (2026-07-27 feedback).
                Button("恢复") {}
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
                    .disabled(true)
            }
            .font(.system(size: 16))
        }
        .padding(15)
        // A firm height (not `maxHeight: .infinity`, which previously caused
        // a real bug: inside a 2-column LazyVGrid with 3+ cards, it made a
        // taller card try to fill *all* remaining scroll-view height rather
        // than just its own row, overlapping row 2). Trimmed back down from
        // 340 (2026-07-28: the bigger card required scrolling to see all 4
        // on Home even though the bigger *window* was the actual ask) while
        // keeping the larger, clearer typography from that pass.
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 244)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var engineBadge: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(session.engine.accentColor)
                .frame(width: 24, height: 24)
                .overlay(
                    session.engine.logoImage
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 13, height: 13)
                )
            Text(session.engine.rawValue)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(session.engine.accentColor)
        }
    }

    /// Stat blocks (label above value, like a KPI tile) instead of plain
    /// text lines — and 上下文 always shows something, even when Codex has
    /// no context reading, so the two engines' cards share one structure
    /// (2026-07-28 feedback: card structure read as inconsistent). Side by
    /// side to save vertical space, but 上下文 gets a 2-line allowance
    /// instead of truncating with "…" when the value is long (e.g.
    /// "≈779.8K tokens（无法确定窗口上限）") — wrapping beats cutting
    /// content off, which was the earlier "content isn't fully shown" bug.
    private var statRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 24) {
                statBlock(label: "上下文", value: session.contextUsage?.description ?? "暂无数据", lineLimit: 2)
                statBlock(label: "记录大小", value: session.recordSizeDescription, lineLimit: 1)
                statBlock(label: "总轮次", value: "\(session.turnCount) 轮", lineLimit: 1)
            }
            if let fraction = session.contextUsage?.fraction {
                ProgressView(value: fraction)
                    .tint(FleetColor.mint)
            }
        }
    }

    private func statBlock(label: String, value: String, lineLimit: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(textColor.opacity(0.4))
            Text(value)
                .font(FleetFont.mono(14.5))
                .fontWeight(.medium)
                .foregroundStyle(textColor.opacity(0.85))
                .lineLimit(lineLimit)
        }
    }

    private var cardBackground: Color { session.engine.cardBackground }

    private var textColor: Color { session.engine.cardTextColor }
}
