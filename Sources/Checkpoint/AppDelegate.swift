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

    /// Shows the prompt and, on submit, appends the entry to the
    /// configured log folder. Also called directly by the "Simulate
    /// Checkpoint Now (debug)" menu item, so it exercises the exact same
    /// path the real timer uses.
    func presentCheckpointPrompt() {
        let settings = AppSettings.shared

        promptWindowController.onSubmit = { [weak self] text in
            do {
                try self?.logger.append(text, to: settings.logFolder)
            } catch {
                print("Checkpoint: failed to write log entry: \(error)")
            }
        }
        promptWindowController.onCancel = {}
        promptWindowController.present(intervalMinutes: settings.interval.minutes)
    }
}
