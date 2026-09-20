import AppKit

/// `ImperatorRetroPong --about-check` builds the real About panel and measures
/// it against brandbook section 10.
///
/// The panel is the one window nobody opens during normal use, so nothing else
/// would notice it drifting. Two of the things it checks have no visible effect
/// until the exact moment they matter: `hidesOnDeactivate`, which only shows
/// when someone clicks away from this `.accessory` app, and the background,
/// which only looks wrong next to a real window.
enum AboutCheck {
    @MainActor
    static func run() -> Int32 {
        // Building a window needs NSApp. Touching `shared` is enough; the app
        // is never run.
        _ = NSApplication.shared

        var failures: [String] = []
        let expect = { (ok: Bool, message: String) in if !ok { failures.append(message) } }

        let panel = AboutPanelController.makePanel()
        let content = panel.contentRect(forFrameRect: panel.frame)
        print("panel \(Int(content.width))x\(Int(content.height))")

        // The brandbook's own numbers, not the app's constants. A check that
        // reads the constant it is checking passes at any value.
        expect(content.width == 300, "panel content is \(content.width)pt wide, brandbook 10.2 says 300")
        expect(content.height == 260, "panel content is \(content.height)pt tall, brandbook 10.2 says 260")

        for (flag, name) in [(NSWindow.StyleMask.titled, "titled"),
                             (.closable, "closable"),
                             (.fullSizeContentView, "fullSizeContentView")] {
            expect(panel.styleMask.contains(flag), "the panel is not .\(name)")
        }
        expect(panel.titlebarAppearsTransparent, "the title bar is not transparent")
        expect(panel.titleVisibility == .hidden, "the title is not hidden")
        expect(panel.isMovableByWindowBackground, "the panel is not movable by its background")

        // An .accessory app deactivates on the first click anywhere else. At
        // the default the panel would hide itself there instead of staying up.
        expect(panel.hidesOnDeactivate == false, "hidesOnDeactivate is true, so the panel hides on the first click outside it")

        // The background is the system's to draw. Anything else is a hand-mixed
        // colour standing in for the standard window material.
        var standard: NSColor?
        var actual: NSColor?
        (panel.appearance ?? NSAppearance(named: .darkAqua)!).performAsCurrentDrawingAppearance {
            standard = NSColor.windowBackgroundColor.usingColorSpace(.sRGB)
            actual = panel.backgroundColor.usingColorSpace(.sRGB)
        }
        if let standard, let actual {
            print(String(format: "background rgb(%d, %d, %d), standard rgb(%d, %d, %d)",
                         Int((actual.redComponent * 255).rounded()),
                         Int((actual.greenComponent * 255).rounded()),
                         Int((actual.blueComponent * 255).rounded()),
                         Int((standard.redComponent * 255).rounded()),
                         Int((standard.greenComponent * 255).rounded()),
                         Int((standard.blueComponent * 255).rounded())))
            expect(actual == standard, "the panel paints its own background instead of the standard window background")
        } else {
            failures.append("could not resolve the panel background")
        }

        expect(panel.appearance?.name == .darkAqua, "the panel is not pinned to darkAqua")

        guard failures.isEmpty else {
            for message in failures { print("FAIL: \(message)") }
            return 1
        }
        print("ABOUT_PANEL_OK")
        return 0
    }
}
