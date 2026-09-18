import SwiftUI

@main
struct CheckpointApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra("Checkpoint", systemImage: "clock") {
            // A plain SettingsLink doesn't activate the app, so the
            // Settings window could open behind other apps' windows
            // (Checkpoint is an accessory app with no Dock icon to click).
            Button("Settings…") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            .keyboardShortcut(",")

            Divider()

            // Triggers the exact same path the real interval timer uses,
            // without waiting out a full interval (minimum 25 minutes).
            Button("Simulate Checkpoint Now (debug)") {
                appDelegate.presentCheckpointPrompt()
            }

            Divider()

            Button("Quit Checkpoint") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(settings: .shared)
        }
    }
}
