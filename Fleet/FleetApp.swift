import SwiftUI

@main
struct FleetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Fleet") {
            RootView()
                .environmentObject(model)
                .onAppear {
                    appDelegate.onWindowActivated = { [weak model] in
                        Task { await model?.refresh() }
                    }
                }
                // V1's design (dark sidebar + light main content, specific
                // card colors) never accounted for the system appearance —
                // following system Dark Mode made "复制命令" and other
                // system-styled buttons render with poor contrast on the
                // light cards at night. Pin to light until the app gets an
                // actual dark theme designed (2026-07-27 feedback).
                .preferredColorScheme(.light)
        }
        // ~35% bigger than the original 900x600 — the whole app window felt
        // small with real content in it, not just an individual card
        // (2026-07-28 feedback, clarifying an earlier "make it bigger" ask
        // that got misapplied to the session cards instead).
        .defaultSize(width: 1220, height: 810)
        .windowResizability(.contentSize)
    }
}
