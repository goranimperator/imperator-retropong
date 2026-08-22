# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

The `Makefile` is the only build path. Do not add a second one.

```bash
make install
```

Builds release into `build/Imperator RetroPong.app`, codesigns, installs to
`/Applications`, and launches. `make install` kills any running instance first.

```bash
make run
make clean
swift build
```

`make run` builds and opens the bundle in place; `swift build` alone is a debug
compile check with no bundle.

No tests or linter configured.

## Release

Follow the `imperator-release` skill. Audit first, tag last, never without
Goran's explicit word in that message.

```bash
make dist VERSION=x.y.z
make release VERSION=x.y.z
```

`dist` is safe — it touches nothing in git or on the remote. `release` bumps
`Info.plist`, commits, tags, pushes, and publishes a **GitHub** release with the
zip attached. The remote is `goranimperator/imperator-retropong` on GitHub.

Signing uses the self-signed `Imperator Dev` identity, not ad-hoc. The app
registers a login item via `SMAppService`, and that registration is keyed to the
bundle's designated requirement — ad-hoc mints a new cdhash per build, so every
update would read as a different app and drop the login item.

`CFBundleShortVersionString` is bumped by the release target and
`CFBundleVersion` comes from `git rev-list --count HEAD`. Never edit either by
hand.

## Architecture

Menu bar popover app (no Dock icon, `LSUIElement = true`) built with SPM. Entry point is `main.swift` which creates `NSApplication` with `.accessory` policy.

**App lifecycle**: `main.swift` → `AppDelegate` → creates `NSStatusItem` (menu bar icon) + `NSPopover` containing `PopoverContentView`.

**Rendering stack**: The game itself is a SpriteKit `GameScene` rendered inside `PopoverContentView` via `GameSKView` (NSViewRepresentable wrapping `GameHostView`). Mouse input is captured via `NSEvent.addLocalMonitorForEvents` in `GameHostView` and forwarded to the scene.

**Key files**:
- `AppDelegate.swift` — status bar icon, popover lifecycle, dark mode + accent color setup
- `PopoverContentView.swift` — SwiftUI layout (header/game/footer), all UI components (`HoverButton`, `LaunchAtLoginToggle`, `SkinSwatch`, `SoundButton`, `ResetButton`), and View extensions
- `GameScene.swift` — SpriteKit game logic (physics, AI paddle, scoring, CRT visual effects)
- `GameConfig.swift` — `AppColors` enum, `Skin` enum (color themes), all game constants (field dimensions, physics categories, pixel font patterns)
- `SoundManager.swift` — singleton, procedurally generates square-wave sounds via AVAudioEngine

**CRT effects** (in `GameScene`): scanlines, RGB subpixel grid, flicker, VHS tracking band, noise overlay, and periodic screen jitter — all layered via SpriteKit nodes on a `crtLayer` at zPosition 100.

## Brand Book

This app follows the Imperator brand book (`~/Code/imperator/imperator-apps-brandbook/BRANDBOOK.md`). Key requirements:
- `AppColors.brand` (`#A01818`) for all accent colors — never use bare `Color.accentColor`
- Dark mode forced via `NSApp.appearance = NSAppearance(named: .darkAqua)`
- Accent override via `UserDefaults.standard.set(0, forKey: "AppleAccentColor")`
- Popover width exception: 280pt (game-specific, not standard 340pt)
- Popover header exception: reads `RetroPong`, not the full `Imperator RetroPong`.
  Brandbook section 4 wants the app name at `.headline`, but the full name measures
  131.8pt against the 94pt the 280pt header leaves once the five skin swatches, reset
  and sound controls are placed, so it truncates. Goran approved dropping the brand
  prefix here on 2026-08-22. The full name still appears in `CFBundleName`,
  `CFBundleDisplayName` and the process name.
- SPM build: no `.xcassets` support, menu bar icon drawn programmatically
- Code signing: self-signed `Imperator Dev` identity, handled by the Makefile

## SPM Notes

Since this is an SPM project (not Xcode), asset catalogs don't compile. The menu bar icon is drawn programmatically in `AppDelegate.setupStatusItem()`. AccentColor.colorset is not applicable — accent is overridden via UserDefaults only.
