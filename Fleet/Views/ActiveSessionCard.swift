import SwiftUI

struct ActiveSessionCard: View {
    let session: SessionRecord
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(FleetColor.mint)
                    .frame(width: 7, height: 7)
                Image(systemName: session.engine.symbolName)
                    .font(.system(size: 11))
                    .foregroundStyle(session.engine.accentColor)
                Text(session.lastActiveDescription)
                    .font(.system(size: 11.5))
                    .foregroundStyle(textColor.opacity(0.6))
                Spacer()
                BookmarkButton(session: session, size: 12)
                    .foregroundStyle(textColor.opacity(session.isBookmarked ? 0.85 : 0.35))
            }

            EditableNameLabel(
                name: session.displayName,
                font: .system(size: 14.5, weight: .medium),
                textColor: textColor.opacity(0.92)
            ) { newName in
                model.rename(session, to: newName)
            }

            if let contextUsage = session.contextUsage {
                VStack(alignment: .leading, spacing: 3) {
                    if let fraction = contextUsage.fraction {
                        ProgressView(value: fraction)
                            .tint(FleetColor.mint)
                    }
                    Text("上下文 · \(contextUsage.description)")
                        .font(.system(size: 11))
                        .foregroundStyle(textColor.opacity(0.65))
                }
            }

            Text("记录大小 · \(session.recordSizeDescription)")
                .font(FleetFont.mono(11))
                .foregroundStyle(textColor.opacity(0.45))

            // Pushes the action buttons to a shared bottom edge regardless
            // of how much text sits above (context-usage line or not) —
            // that, plus the fixed card height below, is what makes every
            // card the same size (2026-07-27 design feedback: cards were
            // reading as inconsistently sized).
            Spacer(minLength: 0)

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
            .padding(.top, 4)
        }
        .padding(14)
        // A firm height (not `maxHeight: .infinity`, which previously caused
        // a real bug: inside a 2-column LazyVGrid with 3+ cards, it made a
        // taller card try to fill *all* remaining scroll-view height rather
        // than just its own row, overlapping row 2). Every card is this
        // exact height regardless of content, per 2026-07-27 feedback that
        // cards should read as uniform, not "however tall the content is."
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 180)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var cardBackground: Color { session.engine.cardBackground }

    private var textColor: Color { session.engine.cardTextColor }
}
