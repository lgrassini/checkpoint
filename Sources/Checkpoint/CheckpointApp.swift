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

            // Temporary: lets the prompt UI be exercised manually before
            // it's wired to the real interval timer in a later PR.
            Button("Test Prompt (debug)") {
                showTestPrompt()
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

    private func showTestPrompt() {
        let controller = appDelegate.promptWindowController
        controller.onSubmit = { text in
            print("Checkpoint entry (not yet logged to file): \(text)")
        }
        controller.onCancel = {}
        controller.present(intervalMinutes: AppSettings.shared.interval.minutes)
    }
}
