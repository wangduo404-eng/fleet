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
                case .browse:
                    MainContentView()
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 820, minHeight: 560)
        .task {
            await model.refresh()
        }
    }
}
