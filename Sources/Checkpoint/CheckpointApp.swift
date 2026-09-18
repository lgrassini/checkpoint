import SwiftUI

@main
struct CheckpointApp: App {
    // The menu bar icon/menu itself is owned entirely by AppDelegate via
    // a plain NSStatusItem — see its file for why.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(settings: .shared)
        }
    }
}
