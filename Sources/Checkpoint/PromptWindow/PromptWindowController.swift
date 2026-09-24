import AppKit
import Combine
import SwiftUI

/// Owns the prompt's NSWindow directly (rather than a SwiftUI `Window`
/// scene) so it can use `setFrameAutosaveName`, which persists the user's
/// chosen size and position across launches — SwiftUI's Window scene has
/// no equivalent for this.
final class PromptWindowController: NSWindowController, NSWindowDelegate {
    // Owned here rather than as @State in PromptView: NSHostingView's
    // rootView reassignment doesn't reliably reset @State between
    // presentations, so this is explicitly cleared before each one.
    private let model = PromptModel()
    private var textCancellable: AnyCancellable?

    private let hostingView = NSHostingView(
        rootView: PromptView(model: PromptModel(), intervalMinutes: 60, onSubmit: { _ in }, onCancel: {})
    )

    var onSubmit: ((String) -> Void)?
    var onCancel: (() -> Void)?
    /// Fires once per presentation, the first time the user types a
    /// non-whitespace character. Used to stop the menu bar icon blink.
    var onFirstKeystroke: (() -> Void)?
    /// Fires whenever the window closes, however it closes (Log It, Skip,
    /// or the titlebar button) — the single place to reliably stop the
    /// blink no matter which path was taken.
    var onWindowClosed: (() -> Void)?

    init() {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.title = "Checkpoint"
        window.isReleasedWhenClosed = false
        // A panel so it can be shown without activating Checkpoint (and so
        // without taking focus from whatever the user is typing in).
        window.isFloatingPanel = true
        window.level = .floating
        // NSPanel hides itself whenever its app is inactive by default —
        // which is always the case once we stop activating the app.
        window.hidesOnDeactivate = false
        // Show on the Space the user is currently in, including over a
        // full-screen app.
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.contentMinSize = NSSize(width: 320, height: 160)
        window.contentView = hostingView

        super.init(window: window)

        // Must come after super.init() (needs `self`) and after the window
        // exists; restores the last saved frame if one is present.
        window.setFrameAutosaveName("PromptWindow")
        window.delegate = self
        updateRootView(intervalMinutes: 60)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(intervalMinutes: Int) {
        updateRootView(intervalMinutes: intervalMinutes)
        // Deliberately neither activating the app nor making the window key:
        // either would take keyboard focus from whatever the user is typing
        // in when a checkpoint fires. orderFrontRegardless shows the panel on
        // top without doing either; clicking into it makes it key (it's a
        // non-activating panel) so they can type without the frontmost app
        // changing.
        window?.orderFrontRegardless()
    }

    // Fires only for user-initiated closes (titlebar button, Cmd+W) — not
    // for our own close() calls after Skip/Log It, which don't go through
    // performClose. Treats a titlebar close the same as Skip.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        onCancel?()
        return true
    }

    // Fires for every close, regardless of how it happened.
    func windowWillClose(_ notification: Notification) {
        onWindowClosed?()
    }

    private func updateRootView(intervalMinutes: Int) {
        model.text = ""

        textCancellable = model.$text
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            .sink { [weak self] _ in
                self?.onFirstKeystroke?()
            }

        hostingView.rootView = PromptView(
            model: model,
            intervalMinutes: intervalMinutes,
            onSubmit: { [weak self] text in
                self?.onSubmit?(text)
                self?.close()
            },
            onCancel: { [weak self] in
                self?.onCancel?()
                self?.close()
            }
        )
    }
}
