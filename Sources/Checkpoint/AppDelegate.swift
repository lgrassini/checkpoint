import AppKit

// Manages the menu bar icon directly via NSStatusItem rather than SwiftUI's
// MenuBarExtra: MenuBarExtra's label wasn't re-rendering on @Published
// changes in manual testing (confirmed via logging that the underlying
// state was toggling correctly — SwiftUI just wasn't reflecting it), so
// the icon needs the direct control CLAUDE.md's Project structure notes
// call for. This owns the whole menu bar presence: icon, blinking, and
// the menu itself.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let promptWindowController = PromptWindowController()
    private lazy var settingsWindowController = SettingsWindowController()
    private let appState = AppState()
    private let logger = CheckpointLogger()

    private var statusItem: NSStatusItem!
    private let iconImage = NSImage(systemSymbolName: "clock", accessibilityDescription: "Checkpoint")
    private var blinkTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hides the Dock icon so Checkpoint runs purely as a menu bar
        // utility. A packaged .app would set this via LSUIElement in
        // Info.plist instead; this executable target has no Info.plist,
        // so it's done programmatically.
        NSApp.setActivationPolicy(.accessory)

        setUpStatusItem()

        appState.onCheckpointDue = { [weak self] in
            self?.presentCheckpointPrompt()
        }
        promptWindowController.onFirstKeystroke = { [weak self] in
            self?.stopBlinking()
        }
        promptWindowController.onWindowClosed = { [weak self] in
            self?.stopBlinking()
        }
    }

    /// Shows the prompt. Submitting or skipping both append an entry to
    /// the configured log folder ("Skipped." for a skip). Also called
    /// directly by the "Simulate Checkpoint Now (debug)" menu item, so it
    /// exercises the exact same path the real timer uses.
    func presentCheckpointPrompt() {
        let settings = AppSettings.shared

        if settings.notificationsEnabled {
            NSSound.beep()
            startBlinking()
        }

        promptWindowController.onSubmit = { [weak self] text in
            self?.log(text, to: settings.logFolder)
        }
        promptWindowController.onCancel = { [weak self] in
            self?.log("Skipped.", to: settings.logFolder)
        }
        promptWindowController.present(intervalMinutes: settings.interval.minutes)
    }

    private func log(_ text: String, to folder: URL) {
        do {
            try logger.append(text, to: folder)
        } catch {
            print("Checkpoint: failed to write log entry: \(error)")
        }
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = iconImage
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let simulate = NSMenuItem(
            title: "Simulate Checkpoint Now (debug)",
            action: #selector(simulateCheckpoint),
            keyEquivalent: ""
        )
        simulate.target = self
        menu.addItem(simulate)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Checkpoint", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    func showSettings() {
        settingsWindowController.show()
    }

    @objc private func openSettings() {
        showSettings()
    }

    @objc private func simulateCheckpoint() {
        presentCheckpointPrompt()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func startBlinking() {
        guard blinkTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let button = self.statusItem.button else { return }
            button.image = (button.image == nil) ? self.iconImage : nil
        }
        RunLoop.main.add(timer, forMode: .common)
        blinkTimer = timer
    }

    private func stopBlinking() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        statusItem.button?.image = iconImage
    }
}
