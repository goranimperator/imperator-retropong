import AppKit
import SpriteKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var gameScene: GameScene!
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        UserDefaults.standard.set(0, forKey: "AppleAccentColor")
        ProcessInfo.processInfo.setValue("Imperator Pong", forKey: "processName")

        setupGameScene()
        setupPopover()
        setupStatusItem()
        setupEventMonitor()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }

        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: NSRect(x: 3, y: 4, width: 12, height: 2), xRadius: 1, yRadius: 1).fill()
            NSBezierPath(ovalIn: NSRect(x: 7.5, y: 8, width: 3, height: 3)).fill()
            NSBezierPath(roundedRect: NSRect(x: 1, y: 13, width: 12, height: 2), xRadius: 1, yRadius: 1).fill()
            return true
        }
        image.isTemplate = true
        button.image = image

        button.target = self
        button.action = #selector(togglePopover)
    }

    private func setupGameScene() {
        gameScene = GameScene(size: CGSize(width: GameConfig.sceneWidth, height: GameConfig.sceneHeight))
        gameScene.scaleMode = .aspectFill
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true

        let contentView = PopoverContentView(
            gameScene: gameScene,
            quitAction: { NSApplication.shared.terminate(nil) }
        )
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.preferredContentSize = NSSize(
            width: GameConfig.sceneWidth,
            height: GameConfig.sceneHeight + 86
        )
        popover.contentSize = hostingController.preferredContentSize
        popover.contentViewController = hostingController
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        gameScene.isPaused = false
        popover.contentViewController?.view.window?.makeKey()
    }

    private func closePopover() {
        popover.performClose(nil)
        gameScene.isPaused = true
    }
}
