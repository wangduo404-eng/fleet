import SwiftUI

@main
struct FleetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Fleet") {
            RootView()
                .environmentObject(model)
                // V1's design (dark sidebar + light main content, specific
                // card colors) never accounted for the system appearance —
                // following system Dark Mode made "复制命令" and other
                // system-styled buttons render with poor contrast on the
                // light cards at night. Pin to light until the app gets an
                // actual dark theme designed (2026-07-27 feedback).
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentSize)
    }
}
