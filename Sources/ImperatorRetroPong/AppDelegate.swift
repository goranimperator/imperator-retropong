import AppKit
import SpriteKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: MenuBarPanel?
    private var gameScene: GameScene?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        UserDefaults.standard.set(0, forKey: "AppleAccentColor")
        ProcessInfo.processInfo.setValue("Imperator RetroPong", forKey: "processName")

        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }

        button.image = StatusItemIcon.make()

        button.target = self
        button.action = #selector(togglePopover)
    }

    @objc private func togglePopover() {
        if panel?.isShown == true {
            closePopover()
        } else {
            showPopover()
        }
    }

    /// Builds the scene, the content and the window from scratch on every open.
    ///
    /// An `SKView` stops its render loop when its window is ordered out, and it
    /// does not start again in that same window: not by unpausing the scene,
    /// not by unpausing the view, and not by detaching and reattaching the
    /// content. All three were measured. `NSPopover` never hit this because it
    /// built a window per show; this panel has to do the same. The cost is that
    /// the board resets when the panel is reopened, which it already did on
    /// every close by pausing.
    private func showPopover() {
        guard let button = statusItem.button else { return }

        let scene = GameScene(size: CGSize(width: GameConfig.sceneWidth, height: GameConfig.sceneHeight))
        scene.scaleMode = .aspectFill
        gameScene = scene

        let contentView = PopoverContentView(
            gameScene: scene,
            aboutAction: { [weak self] in
                self?.closePopover()
                AboutPanelController.show()
            },
            quitAction: { NSApplication.shared.terminate(nil) }
        )
        let panel = MenuBarPanel(content: contentView, width: GameConfig.sceneWidth)
        // The scene has a fixed size, so the height is stated rather than
        // measured: a SpriteKit view has no fitting size to ask for.
        panel.contentHeight = { GameConfig.sceneHeight + 86 }
        panel.onClose = { [weak self] in self?.releasePanel() }
        self.panel = panel

        // Activate first. Ordering a window front while the app is still
        // inactive leaves the activation to undo it.
        NSApp.activate(ignoringOtherApps: true)
        panel.show(from: button)
        panel.makeKey()
    }

    private func closePopover() {
        panel?.close()
    }

    /// Drops the window and the scene once the panel is down, so the next open
    /// builds both again rather than reusing a view that will not draw.
    private func releasePanel() {
        gameScene?.isPaused = true
        panel = nil
        gameScene = nil
    }
}
