import SwiftUI
import AppKit

@main
struct ZenApp: App {
    // This allows us to handle the app lifecycle and hide the dock icon
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Zen", systemImage: "leaf.fill") {
            MainView()
        }
        .menuBarExtraStyle(.window)
    }

    // init removed, moved to AppDelegate
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Boostrap Automation
        _ = AutomationManager.shared

        // Hide dock icon (programmatic version of LSUIElement)
        NSApp.setActivationPolicy(.accessory)
    }
}
