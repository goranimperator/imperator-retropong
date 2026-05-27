import SwiftUI
import SpriteKit
import ServiceManagement

struct PopoverContentView: View {
    let gameScene: GameScene
    let quitAction: () -> Void
    @State private var currentSkin = Skin.current

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            GameSKView(gameScene: gameScene)
                .frame(width: GameConfig.sceneWidth, height: GameConfig.sceneHeight)
            Divider()
            footerView
        }
        .frame(width: GameConfig.sceneWidth)
        .background(.black.opacity(0.15))
    }

    private var headerView: some View {
        HStack {
            Text("Imperator Pong")
                .font(.headline)

            Spacer()

            HStack(spacing: 6) {
                ForEach(Skin.allCases, id: \.self) { skin in
                    SkinSwatch(skin: skin, isSelected: currentSkin == skin) {
                        Skin.current = skin
                        currentSkin = skin
                        gameScene.applySkin()
                    }
                }
            }

            ResetButton(action: { gameScene.reset() })
        }
        .frame(height: 20, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var footerView: some View {
        HStack {
            LaunchAtLoginToggle()

            Spacer()

            HoverButton(action: quitAction) {
                Text("Quit")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct SkinSwatch: View {
    let skin: Skin
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(skin.color))
                .frame(width: 14, height: 14)
                .shadow(color: isSelected ? Color(skin.color).opacity(0.9) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
        .opacity(isHovered || isSelected ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .onHover { isHovered = $0 }
    }
}

struct GameSKView: NSViewRepresentable {
    let gameScene: GameScene

    func makeNSView(context: Context) -> GameHostView {
        GameHostView(gameScene: gameScene)
    }

    func updateNSView(_ nsView: GameHostView, context: Context) {}
}

class GameHostView: NSView {
    private let skView: SKView
    private let gameScene: GameScene
    private var trackingArea: NSTrackingArea?
    private var localMonitor: Any?

    init(gameScene: GameScene) {
        self.gameScene = gameScene
        self.skView = SKView()
        super.init(frame: .zero)

        skView.allowsTransparency = false
        skView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(skView)
        NSLayoutConstraint.activate([
            skView.leadingAnchor.constraint(equalTo: leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: trailingAnchor),
            skView.topAnchor.constraint(equalTo: topAnchor),
            skView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        skView.presentScene(gameScene)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            setupLocalMonitor()
        } else {
            tearDownLocalMonitor()
        }
    }

    private func setupLocalMonitor() {
        guard localMonitor == nil else { return }
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]
        ) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }

    private func tearDownLocalMonitor() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleEvent(_ event: NSEvent) {
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

    deinit {
        tearDownLocalMonitor()
    }
}

struct LaunchAtLoginToggle: View {
    @State private var isEnabled = SMAppService.mainApp.status == .enabled
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Open at Login")
                .font(.caption)
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .scaleEffect(0.55)
                .frame(width: 36, height: 20)
                .tint(Color(red: 0xa0/255.0, green: 0x18/255.0, blue: 0x18/255.0))
                .labelsHidden()
        }
        .foregroundStyle(.primary)
        .opacity(isHovered ? 1.0 : 0.45)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
        .onChange(of: isEnabled) { newValue in
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                isEnabled = SMAppService.mainApp.status == .enabled
            }
        }
    }
}

struct ResetButton: View {
    let action: () -> Void
    @State private var isHovered = false
    @State private var rotation: Double = 0

    var body: some View {
        Button {
            action()
            withAnimation(.interpolatingSpring(stiffness: 60, damping: 8)) {
                rotation -= 360
            }
        } label: {
            if let nsImage = Self.resetImage(size: 14) {
                Image(nsImage: nsImage)
                    .rotationEffect(.degrees(rotation))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .opacity(isHovered ? 1.0 : 0.45)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private static let svg = """
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/><path d="M16 16h5v5"/></svg>
    """

    static func resetImage(size: CGFloat) -> NSImage? {
        guard let data = svg.data(using: .utf8),
              let image = NSImage(data: data) else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: size, height: size)
        return image
    }
}

struct HoverButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label()
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .opacity(isHovered ? 1.0 : 0.45)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
