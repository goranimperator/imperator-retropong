import AppKit
import SpriteKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var gameScene: GameScene!
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupGameScene()
        setupPopover()
        setupStatusItem()
        setupEventMonitor()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }

        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">
          <rect x="5" y="14" width="8" height="2" rx="1" fill="black"/>
          <circle cx="9" cy="7" r="2" fill="black"/>
          <rect x="3" y="1" width="8" height="2" rx="1" fill="black"/>
        </svg>
        """
        if let data = svg.data(using: .utf8), let image = NSImage(data: data) {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            button.image = image
        }

        button.target = self
        button.action = #selector(statusBarClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func setupGameScene() {
        gameScene = GameScene(size: CGSize(width: GameConfig.sceneWidth, height: GameConfig.sceneHeight))
        gameScene.scaleMode = .aspectFill
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: GameConfig.sceneWidth, height: GameConfig.sceneHeight)
        popover.behavior = .transient
        popover.animates = true

        let viewController = GameViewController(gameScene: gameScene)
        popover.contentViewController = viewController
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    @objc private func statusBarClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let skinItem = NSMenuItem(title: "Skin", action: nil, keyEquivalent: "")
        let skinMenu = NSMenu()
        for skin in Skin.allCases {
            let item = NSMenuItem(title: skin.rawValue, action: #selector(changeSkin(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = skin
            if skin == Skin.current {
                item.state = .on
            }
            skinMenu.addItem(item)
        }
        skinItem.submenu = skinMenu
        menu.addItem(skinItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func changeSkin(_ sender: NSMenuItem) {
        guard let skin = sender.representedObject as? Skin else { return }
        Skin.current = skin
        gameScene.applySkin()
    }

    private func togglePopover() {
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
