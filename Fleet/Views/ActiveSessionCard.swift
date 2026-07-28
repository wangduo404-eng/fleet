import SwiftUI

struct ActiveSessionCard: View {
    let session: SessionRecord
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: engine identity is now a labeled badge, not just a
            // small icon — that plus a bigger name below is the fix for
            // "no clear focal point" (2026-07-28 feedback).
            HStack(spacing: 6) {
                engineBadge
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(FleetColor.mint)
                        .frame(width: 6, height: 6)
                    Text(session.lastActiveDescription)
                        .font(.system(size: 11))
                }
                .foregroundStyle(textColor.opacity(0.55))
                BookmarkButton(session: session, size: 12)
                    .foregroundStyle(textColor.opacity(session.isBookmarked ? 0.85 : 0.32))
            }

            EditableNameLabel(
                name: session.displayName,
                font: .system(size: 16.5, weight: .semibold),
                textColor: textColor.opacity(0.95)
            ) { newName in
                model.rename(session, to: newName)
            }
            .padding(.top, 9)

            // Project path was dropped earlier when the name alone seemed
            // to say enough, but a fallback name like "yafo · 6d39dd8f"
            // doesn't actually say which project — bringing it back so the
            // card is a complete picture on its own (2026-07-28 feedback).
            Text(session.projectPath)
                .font(FleetFont.mono(11))
                .foregroundStyle(textColor.opacity(0.5))
                .padding(.top, 2)
                .lineLimit(1)
                .truncationMode(.middle)

            statRow
                .padding(.top, 12)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
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
            .font(.system(size: 12.5))
        }
        .padding(14)
        // A firm height (not `maxHeight: .infinity`, which previously caused
        // a real bug: inside a 2-column LazyVGrid with 3+ cards, it made a
        // taller card try to fill *all* remaining scroll-view height rather
        // than just its own row, overlapping row 2 — see AppModel/git
        // history 2026-07-27). Sized generously above what the tallest
        // content variant needs so nothing clips (2026-07-28: a previous
        // too-tight fixed height was cutting content off).
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 216)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var engineBadge: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(session.engine.accentColor)
                .frame(width: 18, height: 18)
                .overlay(
                    Image(systemName: session.engine.symbolName)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(.white)
                )
            Text(session.engine.rawValue)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(session.engine.accentColor)
        }
    }

    /// Two compact stat blocks (label above value, like a KPI tile) instead
    /// of two plain text lines — and always both, even when Codex has no
    /// context reading, so the two engines' cards share one structure
    /// instead of Claude's being visibly taller (2026-07-28 feedback: card
    /// structure read as inconsistent).
    private var statRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 22) {
                statBlock(label: "上下文", value: session.contextUsage?.description ?? "暂无数据")
                statBlock(label: "记录大小", value: session.recordSizeDescription)
            }
            if let fraction = session.contextUsage?.fraction {
                ProgressView(value: fraction)
                    .tint(FleetColor.mint)
            }
        }
    }

    private func statBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(textColor.opacity(0.4))
            Text(value)
                .font(FleetFont.mono(11.5))
                .fontWeight(.medium)
                .foregroundStyle(textColor.opacity(0.85))
                .lineLimit(1)
        }
    }

    private var cardBackground: Color { session.engine.cardBackground }

    private var textColor: Color { session.engine.cardTextColor }
}
