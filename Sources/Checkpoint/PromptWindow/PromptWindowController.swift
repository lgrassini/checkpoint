import AppKit
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

    private let hostingView = NSHostingView(
        rootView: PromptView(model: PromptModel(), intervalMinutes: 60, onSubmit: { _ in }, onCancel: {})
    )

    var onSubmit: ((String) -> Void)?
    var onCancel: (() -> Void)?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Checkpoint"
        window.isReleasedWhenClosed = false
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
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    // Fires only for user-initiated closes (titlebar button, Cmd+W) — not
    // for our own close() calls after Skip/Log It, which don't go through
    // performClose. Treats a titlebar close the same as Skip.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        onCancel?()
        return true
    }

    private func updateRootView(intervalMinutes: Int) {
        model.text = ""

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
