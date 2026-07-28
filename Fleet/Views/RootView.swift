import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
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
        .frame(minWidth: 1100, minHeight: 750)
        .task {
            await model.refresh()
        }
    }
}
