import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let promptWindowController = PromptWindowController()
    private let appState = AppState()
    private let logger = CheckpointLogger()

    // Hides the Dock icon so Checkpoint runs purely as a menu bar utility.
    // A packaged .app would set this via LSUIElement in Info.plist instead;
    // this executable target has no Info.plist, so it's done programmatically.
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        appState.onCheckpointDue = { [weak self] in
            self?.presentCheckpointPrompt()
        }
    }

    /// Shows the prompt. Submitting or skipping both append an entry to
    /// the configured log folder ("Skipped." for a skip). Also called
    /// directly by the "Simulate Checkpoint Now (debug)" menu item, so it
    /// exercises the exact same path the real timer uses.
    func presentCheckpointPrompt() {
        let settings = AppSettings.shared

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
}
