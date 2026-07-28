import SwiftUI

struct ActiveSessionCard: View {
    let session: SessionRecord
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: engine identity is now a labeled badge, not just a
            // small icon — that plus a bigger name below is the fix for
            // "no clear focal point" (2026-07-28 feedback). Status/time sits
            // on its own row below — at the larger 2026-07-28 sizing, cramming
            // badge + time + bookmark into one row was forcing "Claude Code"
            // to wrap mid-word in the narrower column layout.
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
            .padding(.top, 8)

            EditableNameLabel(
                name: session.displayName,
                font: .system(size: 22, weight: .semibold),
                textColor: textColor.opacity(0.95)
            ) { newName in
                model.rename(session, to: newName)
            }
            .padding(.top, 12)

            // Project path was dropped earlier when the name alone seemed
            // to say enough, but a fallback name like "yafo · 6d39dd8f"
            // doesn't actually say which project — bringing it back so the
            // card is a complete picture on its own (2026-07-28 feedback).
            Text(session.projectPath)
                .font(FleetFont.mono(15))
                .foregroundStyle(textColor.opacity(0.5))
                .padding(.top, 3)
                .lineLimit(1)
                .truncationMode(.middle)

            statRow
                .padding(.top, 16)

            Spacer(minLength: 11)

            HStack(spacing: 11)  {
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
            .font(.system(size: 17))
            .controlSize(.large)
        }
        .padding(19)
        // A firm height (not `maxHeight: .infinity`, which previously caused
        // a real bug: inside a 2-column LazyVGrid with 3+ cards, it made a
        // taller card try to fill *all* remaining scroll-view height rather
        // than just its own row, overlapping row 2 — see AppModel/git
        // history 2026-07-27). Sized generously above what the tallest
        // content variant needs so nothing clips. Bumped ~35% overall
        // (2026-07-28: cards read as too small / cramped even after the
        // hierarchy redesign).
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 340)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var engineBadge: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(session.engine.accentColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: session.engine.symbolName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                )
            Text(session.engine.rawValue)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(session.engine.accentColor)
        }
    }

    /// Stat blocks (label above value, like a KPI tile) instead of plain
    /// text lines — and 上下文 always shows something, even when Codex has
    /// no context reading, so the two engines' cards share one structure
    /// (2026-07-28 feedback: card structure read as inconsistent). 上下文's
    /// value ("≈779.8K tokens（无法确定窗口上限）" and similar) is too long
    /// for a half-width column without truncating with "…" — a second
    /// instance of the "content isn't fully shown" feedback — so it gets
    /// the full card width and can wrap to 2 lines; only 记录大小 (always
    /// short, e.g. "23 MB") stays in a compact single-line block.
    private var statRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            statBlock(label: "上下文", value: session.contextUsage?.description ?? "暂无数据", lineLimit: 2)
            if let fraction = session.contextUsage?.fraction {
                ProgressView(value: fraction)
                    .tint(FleetColor.mint)
            }
            statBlock(label: "记录大小", value: session.recordSizeDescription, lineLimit: 1)
        }
    }

    private func statBlock(label: String, value: String, lineLimit: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(textColor.opacity(0.4))
            Text(value)
                .font(FleetFont.mono(15.5))
                .fontWeight(.medium)
                .foregroundStyle(textColor.opacity(0.85))
                .lineLimit(lineLimit)
        }
    }

    private var cardBackground: Color { session.engine.cardBackground }

    private var textColor: Color { session.engine.cardTextColor }
}
