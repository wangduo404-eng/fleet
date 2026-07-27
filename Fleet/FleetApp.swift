import SwiftUI

@main
struct FleetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Fleet") {
            RootView()
                .environmentObject(model)
        }
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentSize)
    }
}
