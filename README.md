<p align="center">
  <img src="Resources/AppIcon.png" width="128" height="128" alt="Imperator Pong app icon">
</p>

<h1 align="center">Imperator Pong</h1>

<p align="center">
  Pong that lives in the macOS menu bar. Click the icon, a popover drops down
  with a CRT-filtered court, and you play until someone reaches five.
</p>

## Install

Download the latest zip from [Releases](https://github.com/goranimperator/imperator-menu-bar-pong/releases),
unzip, and move `Imperator Pong.app` to `/Applications`.

The app is signed with a self-signed certificate and is not notarized, so
Gatekeeper blocks the first launch. Right-click the app and choose **Open**, or
clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine "/Applications/Imperator Pong.app"
```

Requires macOS 13 or later, Apple silicon. Built and tested on macOS 26 only --
older versions are expected to work but have not been verified.

Install at your own risk. The app is not notarized and carries no Apple
Developer signature, so macOS cannot vouch for it. It is provided as is, with no
warranty, under the [MIT license](LICENSE).

## Permissions

None. The app requests no Accessibility, Input Monitoring, Automation, or
privacy-gated grants, and declares no `NSUsage` keys.

The one system integration is **Open at Login**, the toggle in the popover
footer. It calls `SMAppService.mainApp.register()`, which adds the app to Login
Items in System Settings. macOS may show a notification the first time. Turning
the toggle off unregisters it.

## Use

Click the menu bar icon to open the popover. The game starts as soon as it is
visible and pauses the moment it closes, so nothing runs in the background.

**Move the mouse** left and right over the court to drive the bottom paddle. The
AI plays the top one. First to five points wins.

The header row holds the controls:

| Control | What it does |
|---------|--------------|
| Five colour swatches | Switch skin: Imperator Red, Arcade Green, Neon Blue, Electric Purple, Classic White |
| Reset | Restart the match at 0-0 |
| Speaker | Toggle sound |

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

## Release

Build a zip without touching git or the remote:

```bash
make dist VERSION=1.0.0
```

Cut a full release -- bumps `Info.plist`, commits, tags `v1.0.0`, pushes, and
publishes a GitHub release with the zip attached:

```bash
make release VERSION=1.0.0
```

Requires the [GitHub CLI](https://cli.github.com) (`brew install gh`, then
`gh auth login`). The working tree must be clean. Tags are plain semver
(`v1.0.0`); the release title carries the app name. `CFBundleVersion` is set
from `git rev-list --count HEAD` and is never edited by hand.

## Layout

| Path | Role |
|------|------|
| `Sources/ImperatorPong/main.swift` | Entry point, `.accessory` activation policy |
| `Sources/ImperatorPong/AppDelegate.swift` | Status bar icon, popover lifecycle |
| `Sources/ImperatorPong/PopoverContentView.swift` | SwiftUI layout and controls |
| `Sources/ImperatorPong/GameScene.swift` | SpriteKit physics, AI, scoring, CRT effects |
| `Sources/ImperatorPong/GameConfig.swift` | Colours, skins, constants, pixel font |
| `Sources/ImperatorPong/SoundManager.swift` | Square-wave synthesis via AVAudioEngine |
| `Resources/` | `Info.plist` and app icon |

A SwiftPM executable with no dependencies. `LSUIElement` is true, so there is no
Dock icon and no menu bar menu -- the status item is the entire interface. The
game is a SpriteKit scene hosted inside SwiftUI through `NSViewRepresentable`;
mouse input is captured with a local event monitor and forwarded to the scene.

Because SwiftPM does not compile asset catalogs, the menu bar icon is drawn
programmatically in `AppDelegate.setupStatusItem()` rather than shipped as an
image.

## License

[MIT](LICENSE) &copy; Goran Imperator
