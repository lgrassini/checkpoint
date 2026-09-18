import SwiftUI

@main
struct CheckpointApp: App {
    // The menu bar icon/menu, the prompt window, and the Settings window are
    // all owned by AppDelegate (plain AppKit). The SwiftUI App lifecycle is
    // kept only because it provides the standard main menu (notably Edit, so
    // ⌘C/⌘V/⌘A work in the prompt's text box).
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // A scene is required, and Settings is the one that never opens a
        // window on its own. Its content is intentionally empty — the real
        // window is SettingsWindowController — and its "Settings…" command
        // (⌘,) is redirected there.
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    appDelegate.showSettings()
                }
                .keyboardShortcut(",")
            }
        }
    }
}
