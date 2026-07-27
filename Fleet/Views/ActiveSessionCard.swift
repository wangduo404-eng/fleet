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
                Image(systemName: session.engine == .claudeCode ? "bubble.left.and.bubble.right" : "terminal")
                    .font(.system(size: 11))
                    .foregroundStyle(textColor.opacity(0.6))
                Text(session.lastActiveDescription)
                    .font(.system(size: 11.5))
                    .foregroundStyle(textColor.opacity(0.6))
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

            VStack(alignment: .leading, spacing: 2) {
                Text(session.id)
                    .font(FleetFont.mono(11))
                    .foregroundStyle(textColor.opacity(0.45))
                Text(session.projectPath)
                    .font(FleetFont.mono(11))
                    .foregroundStyle(textColor.opacity(0.45))
                Text("记录大小 · \(session.recordSizeDescription)")
                    .font(FleetFont.mono(11))
                    .foregroundStyle(textColor.opacity(0.45))
            }

            HStack(spacing: 8) {
                Button("复制命令") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(session.resumeCommand, forType: .string)
                }
                .buttonStyle(.bordered)

                Button("恢复") {}
                    .buttonStyle(.borderedProminent)
            }
            .font(.system(size: 12.5))
            .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var cardBackground: Color {
        session.engine == .claudeCode ? FleetColor.claudeCardBackground : FleetColor.codexCardBackground
    }

    private var textColor: Color {
        session.engine == .claudeCode ? .primary : FleetColor.codexCardText
    }
}
