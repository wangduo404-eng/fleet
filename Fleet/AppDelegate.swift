import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "sailboat.fill", accessibilityDescription: "Fleet")
        item.button?.action = #selector(statusItemClicked(_:))
        item.button?.target = self
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
        attachWindowDelegateIfNeeded()
    }

    // LSUIElement apps have no Dock icon, so there's no built-in "reopen
    // when clicked with no windows" behavior. Closing the SwiftUI
    // WindowGroup's only window would otherwise destroy it, leaving
    // `NSApp.windows` empty and this handler's left-click branch a silent
    // no-op forever after (2026-07-28: this, not a real hang, is what
    // looked like Fleet "freezing" — the window had already been closed).
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showQuitMenu()
            return
        }
        attachWindowDelegateIfNeeded()
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.title == "Fleet" {
            window.makeKeyAndOrderFront(nil)
        }
    }

    // Intercept the close button so the window hides instead of being
    // destroyed — keeps it recoverable from the status item indefinitely.
    private func attachWindowDelegateIfNeeded() {
        for window in NSApp.windows where window.title == "Fleet" && window.delegate !== self {
            window.delegate = self
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    private func showQuitMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "退出 Fleet", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
