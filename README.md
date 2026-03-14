# skibidi-alt-tab

A keyboard-driven app switcher for macOS. Press **⌥Space**, type the first letter(s) of an app name, and instantly switch to it — no clicking, no scrolling through a carousel.

## How it works

When you press **Option + Space**, a floating panel appears listing all your running apps. Each app is assigned the shortest unique prefix of its name as a shortcut:

- `S` → Safari
- `SL` → Slack
- `SP` → Spotify
- `T` → Terminal
- `O` → OneNote (vendor prefix "Microsoft" is stripped automatically)
- `W` → Word

Type the shortcut and you're there. If two apps share a prefix, the app waits for you to type one more character to disambiguate. Press **ESC** or click anywhere to dismiss.

## Features

- Low-level keyboard hook via `CGEventTap` — intercepts keypresses before they reach any other app
- Automatic vendor prefix stripping (Microsoft, Adobe, Google, etc.) so you don't have to type the company name
- Scrollable app list
- Works over full-screen apps and across all Spaces
- Runs as a menu bar agent — no Dock icon

## Requirements

- macOS 12+
- Accessibility permission (prompted on first launch)

## Build & run

```bash
git clone https://github.com/Schoji/skibidi-alt-tab.git
cd skibidi-alt-tab
./build_app.sh
open SkibidiAltTab.app
```

On first launch, macOS will ask for Accessibility permission. Grant it in **System Settings → Privacy & Security → Accessibility**.

---

## Disclaimer

I don't know how to write Swift. This app was entirely **vibe-coded using [Claude](https://claude.ai)** as an experiment to see how far you can get without knowing the language. If you find it useful — great!

The idea for this app was inspired by a video by **Adam Basis**:
[https://www.youtube.com/watch?v=pAbf3jtoovA](https://www.youtube.com/watch?v=pAbf3jtoovA)
