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
- [x] **10. Sleep/wake timer behavior** — resolved with no code change:
      Foundation `Timer`'s natural pause-during-sleep/prompt-fire-on-wake
      behavior is good enough. See CLAUDE.md open question 3.
- [ ] **11. Launch at Login** (`SMAppService`) — confirmed in scope, not
      yet implemented.
- [x] **12. Menu bar icon polish** — resolved by keeping the current
      plain SF Symbol `clock`, no change made. See CLAUDE.md open
      question 6.
- [x] **13. Empty-submission validation** — already resolved as a side
      effect of PR 6: "Log It"/Cmd+Return are disabled while the trimmed
      entry is empty. See CLAUDE.md open question 7.

## Notifications (new scope, added after initial planning)

- [x] **14. Notifications setting** — `notificationsEnabled: Bool` in
      `AppSettings` (default on), plus a native checkbox
      (`toggleStyle(.checkbox)`) in a new "Notifications" section of
      Settings UI.
      Validated via unit tests (default value, persistence) and manually
      against the running Settings window.
- [x] **15. Sound on checkpoint** — play `NSSound.beep()` (the user's own
      system alert sound) when a checkpoint fires and notifications are
      enabled. Native, no bundled audio.
      Validated manually against the running app. Also fixed, based on
      manual-test feedback along the way: Settings window opening behind
      other apps' windows (needed to activate the app before
      `openSettings()`), and Settings UI polish (removed a redundant
      legend, clarified the interval slider's section title).
- [x] **16. Blinking menu bar icon** — toggle the status item's icon on a
      0.5s repeating timer while a checkpoint is unanswered; stops as soon
      as the user types the first character in the prompt, or
      submits/skips/closes it.

      Required dropping SwiftUI's `MenuBarExtra` for a plain `NSStatusItem`
      + `NSMenu` owned by `AppDelegate`: `MenuBarExtra`'s label wasn't
      re-rendering on `@Published` changes (confirmed via logging that the
      underlying timer/state genuinely was toggling — SwiftUI just wasn't
      reflecting it in the label). `PromptWindowController` gained
      `onFirstKeystroke` (fires once, via a Combine subscription on the
      first non-empty `$text` emission) and `onWindowClosed` (fires from
      `windowWillClose`, covering all three close paths) to drive when
      blinking stops.

      Validated manually: icon blinks on checkpoint fire, and stops on
      each of the three conditions tested individually (first keystroke,
      Skip, titlebar close).

## Packaging & Launch at Login

- [x] **17. Package as a .app bundle** — `Packaging/Info.plist` +
      `Packaging/build-app.sh` assemble an ad-hoc-signed
      `.build/Checkpoint.app`. Prerequisite for item 11 (Launch at
      Login): `SMAppService` needs a real bundle identifier to register,
      which the bare SwiftPM executable doesn't have. CI now builds the
      bundle on every PR too.
      Validated manually: built the bundle, launched it via `open` (same
      path as a Finder double-click, not direct execution), confirmed no
      Dock icon and the menu bar icon/menu work identically to the
      bare-executable dev build.
- [ ] **11. Launch at Login** (`SMAppService`) — next up, now that the
      app can be meaningfully packaged and tested.

## Validating every PR

- CI runs `swift build` and builds the `.app` bundle (`Packaging/build-app.sh`)
  from PR 1/PR 17 onward respectively, and `swift test` from PR 3 onward.
- Every PR description includes manual verification steps, plus a
  screenshot for anything UI-visible.
- Branch protection on `main` requires the build to pass before merge.
