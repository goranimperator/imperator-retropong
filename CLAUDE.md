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

No tests or linter configured. The one self-check is:

```bash
"build/Imperator RetroPong.app/Contents/MacOS/ImperatorRetroPong" --about-check
```

It builds the real About panel and measures it against brandbook section 10:
size, style mask, `hidesOnDeactivate`, and that the background is the standard
window background rather than a painted colour. Prints `ABOUT_PANEL_OK`.

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

Menu bar panel app (no Dock icon, `LSUIElement = true`) built with SPM. Entry point is `AppMain.swift`, a `@main` struct that creates `NSApplication` with `.accessory` policy.

**App lifecycle**: `AppMain.swift` → `AppDelegate` → creates `NSStatusItem` (menu bar icon) + `MenuBarPanel` containing `PopoverContentView`.

An unrecognised flag exits 2 instead of falling through to `NSApplication.run()`.
Without that guard, running a new check against an older installed binary
launches a second copy of the app with a second menu bar icon.

**Rendering stack**: The game itself is a SpriteKit `GameScene` rendered inside `PopoverContentView` via `GameSKView` (NSViewRepresentable wrapping `GameHostView`). Mouse input is captured via `NSEvent.addLocalMonitorForEvents` in `GameHostView` and forwarded to the scene.

**Key files**:
- `AppDelegate.swift` — status bar icon, panel lifecycle, dark mode + accent color setup
- `MenuBarPanel.swift` — the menu bar surface: borderless `NSPanel`, its corner, placement under the status item, click-outside and Escape dismissal
- `StatusItemIcon.swift` — the menu bar glyph, one factory shared by the status item (18pt) and the panel header (16pt)
- `PopoverContentView.swift` — SwiftUI layout (header/game/footer), all UI components (`HoverButton`, `LaunchAtLoginToggle`, `SkinSwatch`, `SoundButton`, `ResetButton`), and View extensions
- `GameScene.swift` — SpriteKit game logic (physics, AI paddle, scoring, CRT visual effects)
- `GameConfig.swift` — `AppColors` enum, `Skin` enum (color themes), all game constants (field dimensions, physics categories, pixel font patterns)
- `SoundManager.swift` — singleton, procedurally generates square-wave sounds via AVAudioEngine
- `AboutPanel.swift` — About panel (`NSPanel`, 300x260) and its SwiftUI view, built the same way as imperator-widget-clock's
- `AboutCheck.swift` — `--about-check`, which builds the real panel and measures it against brandbook section 10
- `AppMain.swift` — `@main` entry point, `.accessory` policy, and the guard that stops an unknown flag from launching a second copy

**CRT effects** (in `GameScene`): scanlines, RGB subpixel grid, flicker, VHS tracking band, noise overlay, and periodic screen jitter — all layered via SpriteKit nodes on a `crtLayer` at zPosition 100.

## Brand Book

This app follows the Imperator brand book (`~/Code/imperator/imperator-apps-brandbook/BRANDBOOK.md`). Key requirements:
- `AppColors.brand` (`#A01818`) for all accent colors — never use bare `Color.accentColor`
- Dark mode forced via `NSApp.appearance = NSAppearance(named: .darkAqua)`
- Accent override via `UserDefaults.standard.set(0, forKey: "AppleAccentColor")`
- Panel width exception: 280pt (game-specific, not standard 340pt)
- The menu bar surface is a `MenuBarPanel`, not an `NSPopover`. Brandbook 23
  step 5 asks for `NSPopover` with `.transient` and a global mouse-down
  monitor; macOS 27 does not draw its own menu bar panels that way, and
  `NSPopover` exposes no radius to correct it with. The corner constant, the
  reason it is higher than the radius it draws, and the captures behind both
  are documented in `MenuBarPanel.swift`. Do not change them, and do not go
  back to `NSPopover`. The panel owns the click-outside monitor and the
  Escape monitor; `AppDelegate` keeps none of its own.
- Panel header exception: reads `RetroPong`, not the full `Imperator RetroPong`.
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
  - The panel uses the **standard macOS window background**. It sets
    `appearance = .darkAqua` and nothing else: no `backgroundColor`, no
    `.background` on the hosted SwiftUI view. Painting a flat near-black there
    copies the system's job and reads as a different material next to real
    windows. Section 10.2's "Background: Dark (matches app appearance)" means
    this, not a hand-mixed colour.
  - `hidesOnDeactivate = false` on the panel. An `NSPanel` hides itself when
    its app deactivates, and an `.accessory` app deactivates the moment
    anything else is clicked, so at the default the About panel vanishes behind
    the first click outside it instead of staying up until it is closed.
  - Colours follow section 10.3 and imperator-widget-clock exactly:
    `.secondary` for the version, `.tertiary` for the copyright, brand red for
    the website link. Measured against the standard dark window background
    (`#1E1E1E`): headline 16.7:1, version 5.9:1, copyright 2.28:1, link 2.09:1.
    The last two are below the 4.5:1 WCAG AA wants for normal text. Goran chose
    matching widget-clock over the contrast fix on 2026-09-19, so do not
    "correct" them back without asking; raising them means changing the
    brandbook for every app, not this one on its own.
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

Since this is an SPM project (not Xcode), asset catalogs don't compile. The menu bar glyph is drawn in code by `StatusItemIcon.make(size:)`, at 18pt for the status item and 16pt for the panel header; `AppDelegate.setupStatusItem()` only assigns it. AccentColor.colorset is not applicable — accent is overridden via UserDefaults only.
