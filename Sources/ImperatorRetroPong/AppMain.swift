import AppKit

// Menu bar only: no Dock icon, no main window. LSUIElement in Info.plist is what
// keeps the tile out of the Dock, because LaunchServices decides on the tile at
// launch and a policy change from main() arrives too late. The call below is
// still needed for the app switcher, and it is what makes the popover behave as
// an accessory window.
@main
@MainActor
struct ImperatorRetroPongApp {
    /// NSApplication holds its delegate weakly, so keep a strong reference.
    static let delegate = AppDelegate()

    static func main() {
        if CommandLine.arguments.contains("--about-check") {
            exit(AboutCheck.run())
        }
        // An unrecognised flag must not fall through to `run()`. That launches a
        // second copy of the app with a second menu bar icon, and an unknown
        // flag is exactly what an older installed binary sees when a new check
        // is run against it.
        if let unknown = CommandLine.arguments.dropFirst().first(where: { $0.hasPrefix("-") }) {
            FileHandle.standardError.write(
                "ImperatorRetroPong: unknown option \(unknown)\n".data(using: .utf8)!
            )
            FileHandle.standardError.write(
                "usage: ImperatorRetroPong [--about-check]\n".data(using: .utf8)!
            )
            exit(2)
        }

        let application = NSApplication.shared
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
