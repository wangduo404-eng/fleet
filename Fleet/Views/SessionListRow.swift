import SwiftUI

struct SessionListRow: View {
    let session: SessionRecord
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: session.engine.symbolName)
                .font(.system(size: 12))
                .foregroundStyle(session.engine.accentColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                EditableNameLabel(
                    name: session.displayName,
                    font: .system(size: 13),
                    textColor: .primary
                ) { newName in
                    model.rename(session, to: newName)
                }
                Text("\(session.projectPath) · \(session.lastActiveDescription)")
                    .font(FleetFont.mono(11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if session.status == .expired {
                Text("疑似过期")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(FleetColor.expiredText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(FleetColor.expired.opacity(0.25))
                    .clipShape(Capsule())
            }

            Button("复制命令") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(session.resumeCommand, forType: .string)
            }
            .font(.system(size: 11.5))
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}
