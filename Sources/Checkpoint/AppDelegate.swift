import AppKit

// Hides the Dock icon so Checkpoint runs purely as a menu bar utility.
// A packaged .app would set this via LSUIElement in Info.plist instead;
// this executable target has no Info.plist, so it's done programmatically.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
