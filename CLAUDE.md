# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Debug build
swift build

# Release build + install to /Applications
./build.sh

# Manual release build + launch
swift build -c release
cp .build/release/ImperatorPong "Imperator Pong.app/Contents/MacOS/ImperatorPong"
codesign --sign - --force --deep "Imperator Pong.app"
open "Imperator Pong.app"
```

Kill existing instance before relaunching: `pkill -f ImperatorPong`

No tests or linter configured.

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

This app follows the Imperator brand book (`/tmp/imperator-mac-apps-brandbook/BRANDBOOK.md`). Key requirements:
- `AppColors.brand` (`#A01818`) for all accent colors — never use bare `Color.accentColor`
- Dark mode forced via `NSApp.appearance = NSAppearance(named: .darkAqua)`
- Accent override via `UserDefaults.standard.set(0, forKey: "AppleAccentColor")`
- Popover width exception: 280pt (game-specific, not standard 340pt)
- SPM build: no `.xcassets` support, menu bar icon drawn programmatically
- Ad-hoc code signing required: `codesign --sign - --force --deep`

## SPM Notes

Since this is an SPM project (not Xcode), asset catalogs don't compile. The menu bar icon is drawn programmatically in `AppDelegate.setupStatusItem()`. AccentColor.colorset is not applicable — accent is overridden via UserDefaults only.
