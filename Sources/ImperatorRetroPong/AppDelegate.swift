import AppKit
import SpriteKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: MenuBarPanel!
    private var gameScene: GameScene!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        UserDefaults.standard.set(0, forKey: "AppleAccentColor")
        ProcessInfo.processInfo.setValue("Imperator RetroPong", forKey: "processName")

        setupGameScene()
        setupPopover()
        setupStatusItem()
        setupEventMonitor()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }

        button.image = StatusItemIcon.make()

        button.target = self
        button.action = #selector(togglePopover)
    }

    private func setupGameScene() {
        gameScene = GameScene(size: CGSize(width: GameConfig.sceneWidth, height: GameConfig.sceneHeight))
        gameScene.scaleMode = .aspectFill
    }

    private func setupPopover() {
        let contentView = PopoverContentView(
            gameScene: gameScene,
            aboutAction: { [weak self] in
                self?.closePopover()
                AboutPanelController.show()
            },
            quitAction: { NSApplication.shared.terminate(nil) }
        )
        // A MenuBarPanel rather than an NSPopover. macOS 27 draws its own menu
        // bar panels as plain rounded rectangles: a 17.50 pt corner, no arrow
        // and no animation, measured off Control Centre's Wi-Fi panel. An
        // NSPopover draws none of that and exposes none of it for adjustment.
        panel = MenuBarPanel(content: contentView, width: GameConfig.sceneWidth)
        // The scene has a fixed size, so the height is stated rather than
        // measured: a SpriteKit view has no fitting size to ask for.
        panel.contentHeight = { GameConfig.sceneHeight + 86 }
    }

    private func setupEventMonitor() {
        // The click-outside dismissal lives in MenuBarPanel, which owns the
        // same monitor plus the exception for the status item's own click.
        // Pausing the game on close is the panel's business too, so it hangs
        // off onClose rather than off a second monitor.
        panel.onClose = { [weak self] in self?.gameScene.isPaused = true }
    }

    @objc private func togglePopover() {
        if panel.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        panel.show(from: button)
        gameScene.isPaused = false
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()
    }

    private func closePopover() {
        panel.close()
        gameScene.isPaused = true
    }
}
