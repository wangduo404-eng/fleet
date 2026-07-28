import SwiftUI

struct SessionDetailView: View {
    let session: SessionRecord
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            HStack {
                Image(systemName: session.engine.symbolName)
                    .foregroundStyle(session.engine.accentColor)
                Text(session.engine.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(session.engine.accentColor)
                Spacer()
                BookmarkButton(session: session, size: 17)
                    .foregroundStyle(session.isBookmarked ? Color.yellow : Color.secondary)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: 16))

            EditableNameLabel(
                name: session.displayName,
                font: .system(size: 24, weight: .semibold),
                textColor: .primary
            ) { newName in
                model.rename(session, to: newName)
            }

            statusBadge

            Divider()

            VStack(alignment: .leading, spacing: 11) {
                detailRow(label: "Session ID", value: session.id, mono: true)
                detailRow(label: "项目路径", value: session.projectPath, mono: true)
                detailRow(label: "最近活跃", value: session.lastActiveDescription)
                detailRow(label: "记录大小", value: session.recordSizeDescription)
                if let contextUsage = session.contextUsage {
                    detailRow(label: "上下文占用", value: contextUsage.description)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("恢复命令")
                    .font(.system(size: 14.5))
                    .foregroundStyle(.secondary)
                HStack {
                    Text(session.resumeCommand)
                        .font(FleetFont.mono(16))
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("复制命令") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(session.resumeCommand, forType: .string)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(27)
        .frame(width: 565)
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
            Text(session.status.rawValue)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .active: return FleetColor.mint
        case .idle: return .secondary
        case .expired: return FleetColor.expired
        }
    }

    private func detailRow(label: String, value: String, mono: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 14.5))
                .foregroundStyle(.secondary)
            Text(value)
                .font(mono ? FleetFont.mono(17) : .system(size: 17))
                .textSelection(.enabled)
        }
    }
}
