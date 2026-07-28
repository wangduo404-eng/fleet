import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if model.hasAcknowledgedFirstLaunch {
                HStack(spacing: 0) {
                    SidebarView()
                    Group {
                        switch model.viewMode {
                        case .home:
                            HomeView()
                        case .bookmarks:
                            BookmarksView()
                        case .browse:
                            MainContentView()
                        }
                    }
                    .background(Color(nsColor: .windowBackgroundColor))
                }
                .task {
                    await model.refresh()
                }
            } else {
                FirstLaunchNoticeView {
                    model.acknowledgeFirstLaunch()
                }
            }
        }
        .frame(minWidth: 1100, minHeight: 750)
    }
}
