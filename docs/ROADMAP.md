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

- [ ] **8. Wire it together** — timer fires → prompt shows → submit →
      logger appends → resets. Should be small since 3–7 already did the
      real work.
      Validate manually: shrink interval to something short, watch a full
      cycle end-to-end.

## Open-question follow-ups (one decision, one PR each)

- [ ] **9. Missed/skipped checkpoint behavior**
- [ ] **10. Sleep/wake timer behavior**
- [ ] **11. Launch at Login** (`SMAppService`)
- [ ] **12. Menu bar icon polish**
- [ ] **13. Empty-submission validation**

## Validating every PR

- CI runs `swift build` from PR 1 onward, and `swift test` from PR 3
  onward.
- Every PR description includes manual verification steps, plus a
  screenshot for anything UI-visible.
- Branch protection on `main` requires the build to pass before merge.
