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
- The user types free text and submits (Return key or a button). On submit:
  - The entry is appended to `YYYY-MM-DD-Checkpoint.txt` in the configured
    log folder, where the date is *today's* date at submit time.
  - Each entry is timestamped, e.g. `[HH:mm] entry text`, one entry per line
    (or per block — see Open Questions).
  - The prompt window closes and the timer resets for the next interval.
- If the user dismisses/ignores the prompt, nothing is logged for that
  interval (see Open Questions on whether to re-prompt or skip).

## Settings

Two settings only, exposed via a standard macOS Settings window
(`Cmd+,` / Settings menu item):

1. **Log folder** — where daily log files are written. Default: `~/Checkpoint/`.
   Created automatically if it doesn't exist. User can change via a folder
   picker (`NSOpenPanel`, directories only).
2. **Checkpoint interval** — a slider with four discrete stops: **25, 40, 60,
   90 minutes**. Not a freeform slider — snap to these four values only.

Settings persist via `UserDefaults`.

## Platform & tech constraints

- **Swift + SwiftUI/AppKit only.** No third-party dependencies, no Swift
  Package Manager external packages. Only Apple frameworks (SwiftUI, AppKit,
  Foundation, Combine as needed).
- **Native "Mac-assed" feel**: this is the top design priority. Standard
  macOS conventions throughout:
  - Menu bar extra using `MenuBarExtra` (SwiftUI, macOS 13+) or `NSStatusItem`
    if we need more control than `MenuBarExtra` gives us.
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
- Target a reasonably recent macOS baseline (e.g. macOS 13 Ventura+) to allow
  use of modern SwiftUI APIs like `MenuBarExtra`. Confirm minimum deployment
  target before first build.

## File format details (to confirm — see Open Questions)

Log file naming: `YYYY-MM-DD-Checkpoint.txt` in the configured folder, one
file per calendar day, created on first entry of the day.

## Project structure (proposed)

Standard Xcode app target, no external package dependencies:

```
Checkpoint/
  Checkpoint.xcodeproj
  Checkpoint/
    CheckpointApp.swift        // App entry point, MenuBarExtra / status item
    AppState.swift             // Timer logic, interval state, orchestration
    PromptWindow/
      PromptView.swift         // The hourly entry prompt UI
    Settings/
      SettingsView.swift       // Log folder + interval slider
    Logging/
      CheckpointLogger.swift   // File writing, date/filename logic
    Resources/
      Assets.xcassets          // Menu bar icon, app icon
  CLAUDE.md
```

## PR sequence

Development is tracked as a sequence of small, granular, independently
validated pull requests. See [docs/ROADMAP.md](docs/ROADMAP.md) for the
current plan and status.

## Open questions (need your input before/while building)

1. **Missed/skipped checkpoints**: if the user dismisses the prompt or it
   times out unanswered, do we: (a) skip silently, (b) log a placeholder
   like `[HH:mm] (skipped)`, or (c) keep re-prompting/snoozing?
2. **Multiple entries per interval**: can the user reopen the prompt
   manually (e.g. via menu bar click) to log an ad hoc entry outside the
   timer cadence?
3. **Timer behavior on sleep/wake**: should the interval timer pause while
   the Mac is asleep, or count wall-clock time (i.e. catch up / fire
   immediately on wake if overdue)?
4. **App launch behavior**: should Checkpoint offer a "Launch at Login"
   toggle (via `SMAppService`, still no third-party deps)? Not in the
   original spec but common for menu bar utilities — confirm if in scope.
5. **Notification vs. window**: is the prompt strictly an in-app window
   (app must be frontmost-ish to see it), or should it also post a macOS
   notification that deep-links to the prompt?
6. **Menu bar icon**: what should the status item look like — SF Symbol
   (e.g. a clock/checkmark), custom icon, or does it show a countdown/text?
7. **Entry validation**: is an empty submission allowed (logs nothing) or
   blocked (disable submit until text is entered)?
8. **App icon / bundle identifier / product name**: needed for the Xcode
   project setup (e.g. `com.<you>.Checkpoint`).

## Explicitly out of scope (per spec)

- No third-party libraries/dependencies.
- No non-native UI (no custom chrome, no web views).
- No cloud sync, no analytics, no network access at all.
