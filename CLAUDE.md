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

## Toolchain and SDK stamp

Xcode 27, Swift 6.4, macOS 27 SDK. `Package.swift` is on
`swift-tools-version: 6.4` with `swiftSettings: [.swiftLanguageMode(.v5)]` on the
target, because 6.4 turns on Swift 6 language mode and this code is not strict
concurrency clean yet.

`platforms` stays at `.macOS(.v13)`. This is a public repo, the README promises
macOS 13, and `LSMinimumSystemVersion` is 13.0 -- raising it would shut those
users out. The brandbook's "Apps that must still run on older macOS" path applies
here.

That means the SDK has to be stamped at link time, because SwiftPM writes the
`sdk` field of `LC_BUILD_VERSION` from the deployment target, not from the SDK it
compiled against. AppKit picks the control generation from that field, so a plain
`swift build` ships macOS 13 era controls. `SDK_STAMP` in the `Makefile` passes
`-Xlinker -platform_version`; do not remove it, and do not raise `platforms` to
work around it.

Verify after any build that touches the manifest or the Makefile:

```bash
otool -l "build/Imperator RetroPong.app/Contents/MacOS/ImperatorRetroPong" | awk '/LC_BUILD_VERSION/,/^$/'
```

`minos 13.0` with `sdk 27.0` is correct. `sdk` equal to `minos` means the stamp
was lost.

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
- `AboutPanel.swift` — About panel (`NSPanel`, 300x260), its SwiftUI view, and the bundle strings it reads

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
- About panel exceptions (brandbook section 10):
  - The footer trigger reads `About`, not `About Imperator RetroPong`. The full
    label measures 132.0pt against the 106.5pt the footer leaves once
    `Open at Login`, its toggle, the 12pt gap and `Quit` are placed, so it
    overflows by 25.5pt. Same 280pt constraint as the header exception above.
  - Section 10.3 puts the website link in brand red and the copyright at
    `.tertiary`. Both fail WCAG AA on the dark ground: brand red is 2.48:1 and
    `.tertiary` is 2.14:1 against `backgroundNS`, where 4.5:1 is required. The
    link uses `textNormal` -> `textHover` with a brand-red underline on hover
    (11.9:1 / 17.2:1) and the copyright uses `textNormal` at 65% (5.4:1). Brand
    red stays as the accent, on the underline rather than the glyphs.
  - The copyright reads `MIT License`, not brandbook 10.4's
    `All rights reserved` -- this repo ships under MIT, see `LICENSE`.
- Toggle: `.switch`, `scaleEffect(0.55)`, `tint(AppColors.brand)`, and **no**
  `.frame`. The switch is 54x24pt on macOS 27, so a hardcoded frame only adds
  invisible padding while reading as a size guarantee it does not give. The
  control must draw as a wide capsule with an oval knob sitting inside the
  track; a round knob means the SDK stamp above was lost.
- SPM build: no `.xcassets` support, menu bar icon drawn programmatically
- Code signing: self-signed `Imperator Dev` identity, handled by the Makefile

## SPM Notes

Since this is an SPM project (not Xcode), asset catalogs don't compile. The menu bar icon is drawn programmatically in `AppDelegate.setupStatusItem()`. AccentColor.colorset is not applicable — accent is overridden via UserDefaults only.
