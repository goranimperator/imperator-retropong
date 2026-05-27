import AppKit
import SpriteKit

class GameViewController: NSViewController {
    let gameScene: GameScene
    private var skView: SKView!
    private var localMonitor: Any?

    init(gameScene: GameScene) {
        self.gameScene = gameScene
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let frame = NSRect(origin: .zero, size: CGSize(width: GameConfig.sceneWidth, height: GameConfig.sceneHeight))
        self.view = NSView(frame: frame)

        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.width, .height]
        skView.allowsTransparency = false
        skView.presentScene(gameScene)
        view.addSubview(skView)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.acceptsMouseMovedEvents = true
        setupEventMonitor()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func setupEventMonitor() {
        guard localMonitor == nil else { return }
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]
        ) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }

    private func handleEvent(_ event: NSEvent) {
        guard let skView = skView else { return }
        let locationInWindow = event.locationInWindow
        let locationInView = skView.convert(locationInWindow, from: nil)
        guard skView.bounds.contains(locationInView) else { return }
        let locationInScene = gameScene.convertPoint(fromView: locationInView)

        if event.type == .leftMouseDown {
            gameScene.handleClick(locationInScene)
        } else {
            gameScene.handleMousePosition(locationInScene)
        }
    }
}
