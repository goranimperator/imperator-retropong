import AppKit
import Combine
import SpriteKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: MenuBarPanel?
    private var gameScene: GameScene?
    private var updateStatusObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        UserDefaults.standard.set(0, forKey: "AppleAccentColor")
        ProcessInfo.processInfo.setValue("Imperator RetroPong", forKey: "processName")

        setupStatusItem()

        UpdateChecker.shared.start()
        // The update row above the footer appears and disappears with the
        // check's result, and that can happen while the panel is up: Check Now
        // finds a release, or the launch check lands after the first open. The
        // panel's height comes from its content, so show it again to refit it
        // and pin its top edge back under the menu bar. A borderless window
        // that grew on its own would grow from its bottom-left corner, up into
        // the menu bar. Deferred a turn because @Published reports the change
        // before the property holds it.
        updateStatusObserver = UpdateChecker.shared.$status
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refitPanel() }
    }

    private func refitPanel() {
        guard let panel, panel.isShown, let button = statusItem.button else { return }
        panel.show(from: button)
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
        // No contentHeight: the panel measures its content. The game view has a
        // fixed frame in PopoverContentView, so the fitting size is exact, and it
        // takes in the update row and the footer's update controls without a
        // number here going stale every time the footer changes.
        let panel = MenuBarPanel(content: contentView, width: GameConfig.sceneWidth)
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
