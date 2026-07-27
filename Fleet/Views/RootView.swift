import SwiftUI

struct RootView: View {
    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
            MainContentView()
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 820, minHeight: 560)
    }
}
