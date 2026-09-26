import AppKit
import SwiftUI

/// Brandbook 10: a standalone panel, not a sheet and not a second popover.
///
/// Built the same way as imperator-widget-clock's, so the two apps present the
/// same panel. Every number comes from section 10.2 and is checked by
/// `--about-check` rather than trusted, because a panel that is never opened in
/// a test drifts from the spec silently.
@MainActor
enum AboutPanelController {
    /// Brandbook 10.2: 300 x 260.
    ///
    /// The view must not carry an explicit height. A frame is a proposal that
    /// children are free to overflow, and the window then sizes itself to the
    /// overflow instead of to the spec.
    static let width: CGFloat = 300
    static let specifiedHeight: CGFloat = 260

    private static var panel: AboutPanel?

    /// Built without being shown, so `--about-check` measures the real panel
    /// rather than a copy of its numbers.
    static func makePanel() -> AboutPanel {
        let panel = AboutPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: specifiedHeight),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        // An NSPanel hides itself when its app deactivates, and this app is an
        // .accessory that goes inactive the moment anything else is clicked.
        // Left at the default the panel would vanish behind the first click
        // outside it instead of staying up until it is closed.
        panel.hidesOnDeactivate = false
        // No backgroundColor and no background on the hosted view: the panel
        // draws the standard macOS window background. Painting a flat colour
        // here copies the system's job and reads as a different material next
        // to real windows.
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.contentViewController = NSHostingController(rootView: AboutView())
        // Setting contentViewController resizes the window to the hosted view's
        // fitting size, and a SwiftUI view that has not laid out yet reports
        // zero. Without this the panel comes up 0x0 and the contentRect in the
        // initialiser above is thrown away.
        if let hosted = panel.contentViewController?.view {
            hosted.layoutSubtreeIfNeeded()
            panel.setContentSize(NSSize(width: width,
                                        height: max(specifiedHeight, hosted.fittingSize.height)))
        } else {
            panel.setContentSize(NSSize(width: width, height: specifiedHeight))
        }
        return panel
    }

    static func show() {
        if let existing = panel, existing.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let panel = makePanel()
        panel.center()
        // Ordering front is not enough from an .accessory app: without the
        // activation the panel is created behind whatever the user was in.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }
}

/// Closes on Escape, which `NSPanel` does not do on its own for a hosted
/// SwiftUI view. Brandbook 23 step 10 wants Escape to close floating panels.
final class AboutPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }
}

/// Brandbook 10.3, in its order: icon, name, version, copyright, website.
struct AboutView: View {
    @State private var isLinkHovered = false

    /// Both read from the bundle, so the panel cannot claim a version the build
    /// does not carry.
    static func versionText(from bundle: Bundle = .main) -> String {
        let short = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "Version \(short) (Build \(build))"
    }

    /// Brandbook 10.4: the end year is stamped at launch, because a plist
    /// cannot hold a value that moves. The licence is named because this repo
    /// ships under MIT, not "all rights reserved".
    static func copyrightText(year: Int = Calendar.current.component(.year, from: Date())) -> String {
        "© 1986-\(year) Goran Imperator · MIT License"
    }

    static let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Imperator RetroPong"
    static let websiteURL = URL(string: "https://www.goranimperator.com")!

    /// The bundle's own icon, loaded by name rather than through
    /// `NSApp.applicationIconImage`. That property returns an empty image in an
    /// LSUIElement app, and an empty image in SwiftUI is not a 64pt blank: the
    /// view takes no space at all, so the panel lays out short with no icon and
    /// no gap where one should be.
    static var iconImage: NSImage {
        if let named = NSImage(named: "AppIcon") { return named }
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let fromFile = NSImage(contentsOf: url) {
            return fromFile
        }
        return NSApp.applicationIconImage
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: AboutView.iconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)

            Text(AboutView.appName)
                .font(.headline)

            Text(AboutView.versionText())
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(AboutView.copyrightText())
                .font(.caption)
                .foregroundStyle(.tertiary)

            // A Button rather than a Text with a tap gesture: a tap gesture is
            // reachable by the mouse alone, and this is the one link in the app.
            Button {
                NSWorkspace.shared.open(AboutView.websiteURL)
            } label: {
                Text("goranimperator.com")
                    .font(.caption)
                    .foregroundStyle(AppColors.brand)
                    .underline(isLinkHovered)
            }
            .buttonStyle(.plain)
            .onHover { isLinkHovered = $0 }
            .help("Open goranimperator.com")
        }
        .padding(24)
        .frame(width: AboutPanelController.width)
        .fixedSize(horizontal: false, vertical: true)
    }
}
