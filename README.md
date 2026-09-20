<p align="center">
  <img src="Resources/AppIcon.png" width="128" height="128" alt="Imperator RetroPong app icon">
</p>

<h1 align="center">Imperator RetroPong</h1>

<p align="center">
  Pong that lives in the macOS menu bar. Click the icon, a panel drops down
  with a CRT-filtered court, and you play until someone reaches five.
</p>

## Install

Download the latest zip from [Releases](https://github.com/goranimperator/imperator-retropong/releases),
unzip, and move `Imperator RetroPong.app` to `/Applications`.

The app is signed with a self-signed certificate and is not notarized, so
Gatekeeper blocks the first launch. Right-click the app and choose **Open**, or
clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine "/Applications/Imperator RetroPong.app"
```

Requires macOS 13 or later, Apple silicon. Built and tested on macOS 27 only --
older versions are expected to work but have not been verified.

Install at your own risk. The app is not notarized and carries no Apple
Developer signature, so macOS cannot vouch for it. It is provided as is, with no
warranty, under the [MIT license](LICENSE).

## Permissions

None. The app requests no Accessibility, Input Monitoring, Automation, or
privacy-gated grants, and declares no `NSUsage` keys.

The one system integration is **Open at Login**, the toggle in the panel
footer. It calls `SMAppService.mainApp.register()`, which adds the app to Login
Items in System Settings. macOS may show a notification the first time. Turning
the toggle off unregisters it.

## Use

Click the menu bar icon to open the panel. The game starts as soon as it is
visible and pauses the moment it closes, so nothing runs in the background.
Escape closes it, and so does a click anywhere outside.

**Move the mouse** left and right over the court to drive the bottom paddle. The
AI plays the top one. First to five points wins.

The header row holds the controls:

| Control | What it does |
|---------|--------------|
| Five colour swatches | Switch skin: Imperator Red, Arcade Green, Neon Blue, Electric Purple, Classic White |
| Reset | Restart the match at 0-0 |
| Speaker | Toggle sound |

The footer row holds the rest:

| Control | What it does |
|---------|--------------|
| Open at Login | Register or unregister the app as a login item |
| About | Open a panel with version, copyright and the website link. Escape closes it |
| Quit | Quit the app |

The ball speeds up on every paddle hit, from 280 up to a ceiling of 550. Sound is
generated at runtime as square waves -- there are no audio files in the bundle.

The whole court runs through a CRT layer: scanlines, an RGB subpixel grid,
flicker, a VHS tracking band, noise, and an occasional screen jitter.

## Build from source

```bash
make install
```

Builds release, bundles, codesigns, installs to `/Applications`, and launches.
Other targets:

```bash
make run
```

```bash
make clean
```

Signing uses the self-signed `Imperator Dev` identity by default. Override it:

```bash
make build CODESIGN_IDENTITY=-
```

Built with Xcode 27 and Swift 6.4 against the macOS 27 SDK. The minimum stays at
macOS 13.

Those two facts fight each other by default. AppKit decides which generation of
a control to draw from the `sdk` field of the binary's `LC_BUILD_VERSION`, and
SwiftPM writes that field from the deployment target in `Package.swift` rather
than from the SDK it compiled against. A plain `swift build` therefore stamps
`sdk 13.0` and the app draws macOS 13 era controls on macOS 27 -- most visibly a
switch with a round knob that reads as overflowing its track. The `Makefile`
stamps the real SDK at link time instead, so the minimum stays low and the
controls stay current:

```bash
otool -l "build/Imperator RetroPong.app/Contents/MacOS/ImperatorRetroPong" | awk '/LC_BUILD_VERSION/,/^$/'
```

That should report `minos 13.0` and `sdk 27.0`. If `sdk` equals `minos`, the
stamp was lost and every control in the app is a generation behind.

## Release

Build a zip without touching git or the remote:

```bash
make dist VERSION=x.y.z
```

Cut a full release -- bumps `Info.plist`, commits, tags `vx.y.z`, pushes, and
publishes a GitHub release with the zip attached:

```bash
make release VERSION=x.y.z
```

Requires the [GitHub CLI](https://cli.github.com) (`brew install gh`, then
`gh auth login`). The working tree must be clean. Tags are plain semver
(`vx.y.z`); the release title carries the app name. `CFBundleVersion` is set
from `git rev-list --count HEAD` and is never edited by hand.

## Layout

| Path | Role |
|------|------|
| `Sources/ImperatorRetroPong/AppMain.swift` | Entry point, `.accessory` activation policy, unknown-flag guard |
| `Sources/ImperatorRetroPong/AppDelegate.swift` | Status bar icon, panel lifecycle |
| `Sources/ImperatorRetroPong/MenuBarPanel.swift` | The menu bar panel itself: corner, placement, dismissal |
| `Sources/ImperatorRetroPong/StatusItemIcon.swift` | The menu bar glyph, shared by the status item and the header |
| `Sources/ImperatorRetroPong/PopoverContentView.swift` | SwiftUI layout and controls inside the panel |
| `Sources/ImperatorRetroPong/AboutPanel.swift` | About panel: `NSPanel` plus its SwiftUI view |
| `Sources/ImperatorRetroPong/AboutCheck.swift` | `--about-check`, measures the panel against the spec |
| `Sources/ImperatorRetroPong/GameScene.swift` | SpriteKit physics, AI, scoring, CRT effects |
| `Sources/ImperatorRetroPong/GameConfig.swift` | Colours, skins, constants, pixel font |
| `Sources/ImperatorRetroPong/SoundManager.swift` | Square-wave synthesis via AVAudioEngine |
| `Resources/` | `Info.plist` and app icon |

A SwiftPM executable with no dependencies. `LSUIElement` is true, so there is no
Dock icon and no menu bar menu -- the status item is the entire interface. The
game is a SpriteKit scene hosted inside SwiftUI through `NSViewRepresentable`;
mouse input is captured with a local event monitor and forwarded to the scene.

The surface under the menu bar is a borderless `NSPanel` the app draws itself,
not an `NSPopover`. macOS 27 draws its own menu bar panels as plain rounded
rectangles with no arrow and no open or close animation, and `NSPopover` draws
neither that shape nor that corner and exposes no radius to set. The measured
numbers behind that, and the reason the constant is not the number it draws, are
in `MenuBarPanel.swift`.

Because SwiftPM does not compile asset catalogs, the menu bar icon is drawn
programmatically in `AppDelegate.setupStatusItem()` rather than shipped as an
image.

## License

[MIT](LICENSE) &copy; Goran Imperator
