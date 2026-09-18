# Checkpoint

A native macOS menu bar app that periodically prompts the user to log what they
spent the last interval doing, and appends each entry to a plain-text daily
log file.

## Core behavior

- Lives in the macOS menu bar (`NSStatusItem`). No Dock icon, no main window
  (`LSUIElement` / accessory app). This is a menu-bar-only utility.
- Runs a repeating timer. When it fires, it shows a small prompt window
  asking "What did you spend the last hour on?" (wording should reference the
  actual configured interval, not hardcode "hour").
- The user types free text and submits (Cmd+Return, or the "Log It" button —
  plain Return inserts a newline since entries are multi-line). On submit:
  - The entry is appended to `YYYY-MM-DD-Checkpoint.txt` in the configured
    log folder, where the date is *today's* date at submit time.
  - New files start with a date header (e.g. `Fri Sep, 18 2026`) followed by
    a blank line. Each entry is written as `[HH:mm] \n<entry text>\n\n\n` —
    a blank line after the timestamp, two trailing blank lines separating it
    from the next entry.
  - The prompt window closes and the timer resets for the next interval.
- Clicking "Skip" (or Escape), or closing the window via the titlebar
  button (or Cmd+W), both log a `Skipped.` entry in the same format,
  rather than logging nothing.
- **Notifications** (opt-out via Settings, on by default): when a
  checkpoint fires,
  - plays `NSSound.beep()` (the user's own configured system alert sound —
    respects their System Settings volume/mute; no bundled audio), and
  - blinks the menu bar icon on a short repeating timer, until the user
    types the first character into the prompt, or submits/skips/closes it.

## Settings

Three settings, exposed via a standard macOS Settings window
(`Cmd+,` / Settings menu item):

1. **Log folder** — where daily log files are written. Default: `~/Checkpoint/`.
   Created automatically if it doesn't exist. User can change via a folder
   picker (`NSOpenPanel`, directories only).
2. **Checkpoint interval** — a slider with four discrete stops: **25, 40, 60,
   90 minutes**. Not a freeform slider — snap to these four values only.
3. **Notifications** — a checkbox (native `.toggleStyle(.checkbox)`)
   enabling/disabling the sound + menu bar icon blink described above.
   Defaults to on.

Settings persist via `UserDefaults`.

## Platform & tech constraints

- **Swift + SwiftUI/AppKit only.** No third-party dependencies — the project
  is structured as a Swift Package (see Project structure below) purely as
  a build-format choice, but it declares zero external package dependencies.
  Only Apple frameworks (SwiftUI, AppKit, Foundation, Combine as needed).
- **Native "Mac-assed" feel**: this is the top design priority. Standard
  macOS conventions throughout:
  - Menu bar icon/menu via a plain `NSStatusItem` + `NSMenu` (owned by
    `AppDelegate`), not SwiftUI's `MenuBarExtra` — tried `MenuBarExtra`
    first, but its label didn't re-render in response to `@Published`
    changes (needed for the icon blink; confirmed via logging that the
    underlying state *was* updating correctly, SwiftUI just wasn't
    reflecting it), so this is the "more control" escape hatch.
  - Settings window follows the standard macOS Settings scene pattern
    (`Settings {}` scene in SwiftUI, or a standard preferences window in
    AppKit) — not a custom-chrome window.
  - Prompt window should feel like a native alert/small panel — system
    fonts, system spacing, standard button placement (default button on the
    right, primary action responds to Return, Escape cancels/dismisses),
    supports Light/Dark mode automatically via system colors.
  - Respect standard macOS behaviors: window can be moved, prompt shouldn't
    steal focus aggressively beyond what's needed, app should launch fast
    and stay lightweight (idle CPU/memory footprint near zero between
    prompts).
- **Lightweight**: minimal background work — a single timer, no polling
  loops, no unnecessary observers.
- Minimum deployment target: **macOS 14 Sonoma**.

## File format details

Log file naming: `YYYY-MM-DD-Checkpoint.txt` in the configured folder, one
file per calendar day, created on first entry of the day. See Core behavior
above for the exact entry format.

## Project structure

Swift Package (`Package.swift`), executable target, no external
dependencies. Opens and runs directly in Xcode via "Open Package...":

```
Checkpoint/
  Package.swift
  Sources/Checkpoint/
    CheckpointApp.swift    // App entry point (just the Settings scene)
    AppDelegate.swift      // Menu bar NSStatusItem/NSMenu, icon blink, wiring
    AppState.swift         // Timer logic, interval state, orchestration
    PromptWindow/
      PromptView.swift     // The interval entry prompt UI
    Settings/
      SettingsView.swift   // Log folder + interval slider
    Logging/
      CheckpointLogger.swift  // File writing, date/filename logic
    Resources/
      Assets.xcassets      // App icon (menu bar icon is an SF Symbol)
  Tests/CheckpointTests/              // Unit tests (added PR 3)
  CLAUDE.md
```

Bundle identifier: `com.warp.Checkpoint`. Code signing: sign-to-run-locally
for now (no Apple Developer Team). Packaging the built executable into a
distributable `.app` bundle (Info.plist embedding, icon, bundle assembly) is
its own later step, not required for local development or CI builds.

## PR sequence

Development is tracked as a sequence of small, granular, independently
validated pull requests. See [docs/ROADMAP.md](docs/ROADMAP.md) for the
current plan and status.

## Open questions (need your input before/while building)

1. **Missed/skipped checkpoints**: resolved. Explicit Skip and closing the
   window via the titlebar button (or Cmd+W) both log a `Skipped.` entry
   (see Core behavior). By product decision, the prompt intentionally has
   no timeout, auto-skip, or snooze — it stays open indefinitely if
   ignored, since the minimum 25-minute interval makes that low cost.
2. **Multiple entries per interval**: can the user reopen the prompt
   manually (e.g. via menu bar click) to log an ad hoc entry outside the
   timer cadence?
3. **Timer behavior on sleep/wake**: resolved — relying on Foundation
   `Timer`'s natural behavior (no new code). The run loop effectively
   pauses while the Mac is asleep; on wake, an already-passed fire date
   triggers promptly and the repeating timer resumes its normal cadence
   from there. Close enough to "wall-clock, catch up on wake" without
   needing explicit `NSWorkspace` sleep/wake notification handling.
4. **App launch behavior**: resolved — yes, in scope. A "Launch at Login"
   toggle via `SMAppService` is being added (see PR sequence).
5. **Notification vs. window**: still open. The prompt is strictly an
   in-app window; PRs 14–16 added a sound + blinking menu bar icon as
   attention-getters, but not a formal `UNUserNotificationCenter` alert
   that could deep-link to the prompt from outside the app.
6. **Menu bar icon**: resolved — keeping the plain SF Symbol `clock`
   (monochrome, adapts to menu bar light/dark automatically). No custom
   asset.
7. **Entry validation**: resolved — blocked. "Log It" (and its Cmd+Return
   shortcut) is disabled while the trimmed entry is empty; `submit()` also
   guards against it. Has been the behavior since PR 6.
8. **App icon**: still needed (bundle identifier and product name are
   resolved — see Project structure).

## Explicitly out of scope (per spec)

- No third-party libraries/dependencies.
- No non-native UI (no custom chrome, no web views).
- No cloud sync, no analytics, no network access at all.
