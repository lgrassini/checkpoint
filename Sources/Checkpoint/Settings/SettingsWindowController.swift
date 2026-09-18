import AppKit
import SwiftUI

/// Owns the Settings window directly instead of using SwiftUI's `Settings`
/// scene. Opening that scene from this accessory app via
/// `NSApp.sendAction(showSettingsWindow:)` worked once, but not again after
/// the window had been closed. A plain NSWindow that's shown/hidden (never
/// released) reopens reliably — the same approach PromptWindowController
/// already uses.
final class SettingsWindowController: NSWindowController {
    private let launchAtLogin: LaunchAtLogin

    init(settings: AppSettings = .shared, launchAtLogin: LaunchAtLogin = LaunchAtLogin()) {
        self.launchAtLogin = launchAtLogin
        let window = NSWindow(
            contentViewController: NSHostingController(
                rootView: SettingsView(settings: settings, launchAtLogin: launchAtLogin)
            )
        )
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false

        super.init(window: window)

        // Restores the last position if there is one; otherwise center.
        if !window.setFrameAutosaveName("SettingsWindow") {
            window.center()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        // The window is reused rather than recreated, so re-read the login
        // item state in case it was changed in System Settings meanwhile.
        launchAtLogin.refresh()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
