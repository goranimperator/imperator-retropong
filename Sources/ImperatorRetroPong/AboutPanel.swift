import AppKit
import SwiftUI

enum AboutInfo {
    static let websiteURL = URL(string: "https://www.goranimperator.com")!
    static let websiteLabel = "goranimperator.com"

    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Imperator RetroPong"
    }

    static var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "Version \(short) (Build \(build))"
    }

    static var copyright: String {
        let year = Calendar.current.component(.year, from: Date())
        return "© 1986-\(year) Goran Imperator · MIT License"
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)
            }

            Text(AboutInfo.appName)
                .font(.headline)
                .foregroundStyle(AppColors.textHover)

            Text(AboutInfo.version)
                .font(.caption)
                .foregroundStyle(AppColors.textNormal.opacity(0.85))

            Text(AboutInfo.copyright)
                .font(.caption)
                .foregroundStyle(AppColors.textNormal.opacity(0.65))

            WebsiteLink()
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(AppColors.backgroundNS))
    }
}

struct WebsiteLink: View {
    @State private var isHovered = false

    var body: some View {
        Button {
            NSWorkspace.shared.open(AboutInfo.websiteURL)
        } label: {
            Text(AboutInfo.websiteLabel)
                .font(.caption)
                .foregroundStyle(isHovered ? AppColors.textHover : AppColors.textNormal)
                .underline(isHovered, color: AppColors.brand)
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
        .accessibilityLabel("Open \(AboutInfo.websiteLabel)")
    }
}

/// Closes on Escape, which `NSPanel` does not do on its own for a hosted SwiftUI view.
final class AboutPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }
}

final class AboutPanelController {
    private var panel: AboutPanel?

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel() -> AboutPanel {
        let size = NSSize(width: 300, height: 260)
        let panel = AboutPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = AppColors.backgroundNS

        let hostingController = NSHostingController(rootView: AboutView())
        hostingController.preferredContentSize = size
        panel.contentViewController = hostingController
        panel.setContentSize(size)
        panel.center()

        return panel
    }
}
