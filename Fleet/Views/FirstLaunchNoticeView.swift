import SwiftUI

/// Shown once, before the very first scan ever runs, so a new user isn't
/// surprised to see their own session history appear with no warning.
/// Fleet's scan is entirely local and read-only, but that isn't obvious
/// just from opening the app — this makes it explicit up front instead of
/// leaving it to the README.
struct FirstLaunchNoticeView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("⛵️")
                .font(.system(size: 40))

            Text("开始之前")
                .font(FleetFont.brandTitle(28))

            VStack(alignment: .leading, spacing: 14) {
                noticeRow("Fleet 会读取本机 ~/.claude 和 ~/.codex 目录下的 session 记录（项目路径、活跃状态、上下文占用等），用来在这里展示。")
                noticeRow("Session 数据只留在这台电脑上，不会上传到任何地方。Fleet 唯一的网络请求是启动时去 GitHub 查一下有没有新版本，不涉及任何 session 内容。")
                noticeRow("重命名和书签保存在 Fleet 自己的本地文件里，不会写回 Claude Code 或 Codex。")
            }

            Button("知道了，开始扫描", action: onAcknowledge)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 6)
        }
        .padding(40)
        .frame(maxWidth: 480, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func noticeRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(FleetColor.mint)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
