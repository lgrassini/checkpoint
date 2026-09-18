# Checkpoint

A lightweight, native macOS menu bar app that checks in with you on a
timer, asking what you've been doing, and keeps a plain-text log of the
answers.

## Features

- Lives in the menu bar only — no Dock icon, no windows until you need them.
- Prompts you on a configurable interval (25, 40, 60, or 90 minutes) for a
  quick log entry.
- Appends entries to a daily plain-text file (`YYYY-MM-DD-Checkpoint.txt`)
  in a folder you choose.
- Optional sound + blinking menu bar icon to flag when a checkpoint is due.
- Launch at Login support.
- 100% native Swift, SwiftUI, and AppKit — zero third-party dependencies.

## Requirements

- macOS 14 Sonoma or later
- Xcode 15+ (for building/testing; the app itself has no dependencies)

## Building & running

This is a Swift Package, not an `.xcodeproj` — open it directly in Xcode
via **File > Open…** and selecting the project folder, or build from the
terminal:

```bash
swift build
swift run
```

## Settings

- **Log folder** — where daily log files are written. Defaults to
  `~/Checkpoint/`.
- **Checkpoint interval** — 25, 40, 60, or 90 minutes.
- **Notifications** — sound + menu bar icon blink when a checkpoint is due,
  on by default.
- **Launch at login** — start Checkpoint automatically when you log in.

## Project docs

- [CLAUDE.md](CLAUDE.md) — full spec, architecture, and open questions.
- [docs/ROADMAP.md](docs/ROADMAP.md) — PR-by-PR development roadmap.
