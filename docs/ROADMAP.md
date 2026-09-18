# Checkpoint — PR Roadmap

Tracks the planned pull request sequence for building Checkpoint. Small,
granular PRs, each independently buildable and reviewable. Check items off
as PRs merge; add new items as scope evolves (e.g. resolved open questions
from [CLAUDE.md](../CLAUDE.md)).

## Foundational

- [x] **1. Repo scaffolding** — Swift Package skeleton (empty executable
      target, `com.warp.Checkpoint`, macOS 14 deployment target),
      `.gitignore` for SwiftPM/Xcode build artifacts, and a GitHub Actions
      workflow running `swift build` on every PR. No functionality yet —
      just a green CI build on an empty app.

## Core pieces, built independently

- [x] **2. Menu bar shell** — `MenuBarExtra`, Dock icon hidden via
      `NSApp.setActivationPolicy(.accessory)` (no Info.plist to set
      `LSUIElement` in a SwiftPM executable), placeholder clock icon, Quit
      menu item.
      Validated manually: app launches, sits in the menu bar, quits cleanly.
- [x] **3. Settings model** — `AppSettings` backed by `UserDefaults` (log
      folder + interval, with defaults).
      Validated via unit tests in `CheckpointTests`: default values,
      persistence round-trip, the four allowed interval values, fallback
      to default on an invalid stored interval. CI now runs `swift test`.
- [x] **4. Settings UI** — SwiftUI Settings scene wired to `AppSettings`:
      folder picker (`NSOpenPanel`, directories only, can create folders),
      4-stop slider. Reachable via a Settings… item (⌘,) in the menu bar
      menu.
      Validated manually against the running app.
- [x] **5. CheckpointLogger** — filename-from-date logic, folder creation,
      timestamped append.
      Validated via unit tests writing to a temp directory: filename
      formatting, folder auto-creation, line format, same-day append,
      different-day files.
- [x] **6. Prompt window UI** — `PromptView` (multi-line `TextEditor`,
      Skip/Log It), presented via `PromptWindowController` (an AppKit
      `NSWindowController` using `setFrameAutosaveName` so the window's
      size/position persist across launches — SwiftUI's `Window` scene has
      no equivalent). Triggered by a temporary "Test Prompt" debug menu
      item (not yet wired to the real timer).
      Validated manually: multi-line entry, window resizes and the text
      box adapts, Cmd+Return submits, remembered size/position across
      relaunch.
- [x] **7. Timer/orchestration (`AppState`)** — interval scheduling behind
      a `CheckpointScheduling` protocol (`TimerScheduler` wraps a real
      Foundation `Timer`), so `AppState` reschedules on interval changes
      and fires `onCheckpointDue` without any test needing to wait on real
      time.
      Validated via unit tests with a fake scheduler: initial scheduling,
      rescheduling on interval change, firing invokes the callback,
      cancel on deinit. Not yet wired to the prompt/logger (PR 8), so no
      manual verification needed for this one.

## Integration

- [x] **8. Wire it together** — `AppDelegate` owns `AppState` and wires
      `onCheckpointDue` to `presentCheckpointPrompt()`, which shows the
      prompt and, on submit or skip, appends via `CheckpointLogger` to
      `AppSettings.logFolder` ("Skipped." for a skip — see open question 1
      below). The debug menu item calls the same method directly, since
      the minimum interval (25 min) makes waiting out a real cycle
      impractical for manual testing.

      Manual testing during this PR also surfaced and fixed two bugs:
      the prompt's text box didn't reset between presentations (fixed by
      moving its state into an `ObservableObject` explicitly reset by
      `PromptWindowController` before each presentation), and the log
      entry format was reworked to include a per-file date header and
      correct blank-line spacing.

      Validated manually end-to-end multiple times: triggered via the
      debug item, typed a multi-line entry, submitted with Cmd+Return,
      confirmed the entry landed correctly in the file, confirmed the
      box is empty on reopen and "Log It" enables as text is typed, and
      confirmed Skip logs "Skipped.".

## Open-question follow-ups (one decision, one PR each)

- [x] **9. Missed/skipped checkpoint behavior** — closing the prompt via
      the titlebar button (or Cmd+W) now logs "Skipped.", same as
      clicking Skip, via `NSWindowDelegate.windowShouldClose(_:)` (only
      fires for user-initiated closes, not our own `close()` calls, so no
      double-logging). No timeout/auto-skip/snooze, by product decision.
      Validated manually: closed via the titlebar button and confirmed
      "Skipped." was logged.
- [ ] **10. Sleep/wake timer behavior**
- [ ] **11. Launch at Login** (`SMAppService`)
- [ ] **12. Menu bar icon polish**
- [ ] **13. Empty-submission validation**

## Notifications (new scope, added after initial planning)

- [x] **14. Notifications setting** — `notificationsEnabled: Bool` in
      `AppSettings` (default on), plus a native checkbox
      (`toggleStyle(.checkbox)`) in a new "Notifications" section of
      Settings UI.
      Validated via unit tests (default value, persistence) and manually
      against the running Settings window.
- [ ] **15. Sound on checkpoint** — play `NSSound.beep()` (the user's own
      system alert sound) when a checkpoint fires and notifications are
      enabled. Native, no bundled audio.
- [ ] **16. Blinking menu bar icon** — toggle the status item's icon on a
      short repeating timer while a checkpoint is unanswered; stop as soon
      as the user types the first character in the prompt, or
      submits/skips/closes it.

## Validating every PR

- CI runs `swift build` from PR 1 onward, and `swift test` from PR 3
  onward.
- Every PR description includes manual verification steps, plus a
  screenshot for anything UI-visible.
- Branch protection on `main` requires the build to pass before merge.
