import SwiftUI

struct SessionListRow: View {
    let session: SessionRecord
    let onSelect: () -> Void
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 13) {
            session.engine.logoImage
                .resizable()
                .scaledToFit()
                .foregroundStyle(session.engine.accentColor)
                .frame(width: 17, height: 17)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                EditableNameLabel(
                    name: session.displayName,
                    font: .system(size: 16),
                    textColor: .primary
                ) { newName in
                    model.rename(session, to: newName)
                }
                Text("\(session.projectPath) · \(session.lastActiveDescription)")
                    .font(FleetFont.mono(14))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)

            Spacer()

            BookmarkButton(session: session, size: 15)
                .foregroundStyle(session.isBookmarked ? Color.yellow : Color.secondary.opacity(0.5))

            if session.status == .expired {
                Text("疑似过期")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FleetColor.expiredText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(FleetColor.expired.opacity(0.25))
                    .clipShape(Capsule())
            }

            Button("复制命令") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(session.resumeCommand, forType: .string)
            }
            .font(.system(size: 14.5))
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 5)
    }
}
