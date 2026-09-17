# Checkpoint — PR Roadmap

Tracks the planned pull request sequence for building Checkpoint. Small,
granular PRs, each independently buildable and reviewable. Check items off
as PRs merge; add new items as scope evolves (e.g. resolved open questions
from [CLAUDE.md](../CLAUDE.md)).

## Foundational

- [ ] **1. Repo scaffolding** — Xcode project skeleton (empty menu-bar app
      target, bundle ID, deployment target), `.gitignore` for
      Xcode/DerivedData, and a GitHub Actions workflow running
      `xcodebuild build` on every PR. No functionality yet — just a green
      CI build on an empty app.

## Core pieces, built independently

- [ ] **2. Menu bar shell** — `MenuBarExtra`/`NSStatusItem`, `LSUIElement`
      (no Dock icon), placeholder icon, Quit menu item.
      Validate manually: app launches, sits in the menu bar, quits cleanly.
- [ ] **3. Settings model** — `AppSettings` backed by `UserDefaults` (log
      folder + interval, with defaults).
      Validate via unit tests: default values, persistence round-trip,
      interval snapping to 25/40/60/90.
- [ ] **4. Settings UI** — SwiftUI Settings scene wired to `AppSettings`:
      folder picker (`NSOpenPanel`), 4-stop slider.
      Validate manually against the running app.
- [ ] **5. CheckpointLogger** — filename-from-date logic, folder creation,
      timestamped append.
      Validate via unit tests writing to a temp directory (most
      test-worthy piece in the app).
- [ ] **6. Prompt window UI** — `PromptView` alone, triggered by a
      temporary "Test Prompt" debug menu item (not yet wired to the real
      timer).
      Validate manually, screenshot in the PR description.
- [ ] **7. Timer/orchestration (`AppState`)** — interval scheduling logic,
      injectable clock if feasible so firing logic is testable without
      waiting real minutes.
      Validate via unit tests where possible, manual otherwise.

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

- CI runs `xcodebuild build` from PR 1 onward, and `xcodebuild test` once a
  test target exists (from PR 3).
- Every PR description includes manual verification steps, plus a
  screenshot for anything UI-visible.
- Branch protection on `main` requires the build to pass before merge.
