import SwiftUI

@main
struct CheckpointApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Checkpoint", systemImage: "clock") {
            SettingsLink {
                Text("Settings…")
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
