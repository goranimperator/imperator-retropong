import AppKit

enum Skin: String, CaseIterable {
    case red = "Imperator Red"
    case green = "Arcade Green"
    case blue = "Neon Blue"
    case purple = "Electric Purple"
    case white = "Classic White"

    var color: NSColor {
        switch self {
        case .red:    return NSColor(red: 0xa0/255, green: 0x18/255, blue: 0x18/255, alpha: 1)
        case .blue:   return NSColor(red: 0x18/255, green: 0x40/255, blue: 0xd4/255, alpha: 1)
        case .purple: return NSColor(red: 0x8b/255, green: 0x18/255, blue: 0xd4/255, alpha: 1)
        case .green:  return NSColor(red: 0, green: 1, blue: 0, alpha: 1)
        case .white:  return .white
        }
    }

    var dimAlpha: CGFloat { 0.25 }

    static var current: Skin {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "skin"),
                  let skin = Skin(rawValue: raw) else { return .red }
            return skin
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "skin") }
    }
}

enum GameConfig {
    static let sceneWidth: CGFloat = 280
    static let sceneHeight: CGFloat = 330

    static let px: CGFloat = 4

    static let fieldMinX: CGFloat = 0
    static let fieldMaxX: CGFloat = sceneWidth
    static let fieldMinY: CGFloat = 0
    static let fieldMaxY: CGFloat = sceneHeight

    static let paddleWidth: CGFloat = 14 * px
    static let paddleHeight: CGFloat = 2 * px
    static let paddleInset: CGFloat = 5 * px
    static let playerPaddleY: CGFloat = fieldMinY + paddleInset
    static let aiPaddleY: CGFloat = fieldMaxY - paddleInset

    static let ballSize: CGFloat = 2 * px
    static let initialBallSpeed: CGFloat = 280
    static let maxBallSpeed: CGFloat = 550
    static let speedIncrement: CGFloat = 12

    static let aiSpeed: CGFloat = 230
    static let aiErrorMargin: CGFloat = 12

    static let ballCategory: UInt32   = 0x1 << 0
    static let paddleCategory: UInt32 = 0x1 << 1
    static let wallCategory: UInt32   = 0x1 << 2
    static let goalCategory: UInt32   = 0x1 << 3

    static let winningScore: Int = 10

    static let scorePixel: CGFloat = 6
    static let scoreInsetX: CGFloat = 50
    static let messageOffsetY: CGFloat = 30

    static let messagePixel: CGFloat = 3

    static let digitPatterns: [[UInt8]] = [
        [0b111, 0b101, 0b101, 0b101, 0b111],
        [0b010, 0b110, 0b010, 0b010, 0b111],
        [0b111, 0b001, 0b111, 0b100, 0b111],
        [0b111, 0b001, 0b111, 0b001, 0b111],
        [0b101, 0b101, 0b111, 0b001, 0b001],
        [0b111, 0b100, 0b111, 0b001, 0b111],
        [0b111, 0b100, 0b111, 0b101, 0b111],
        [0b111, 0b001, 0b010, 0b010, 0b010],
        [0b111, 0b101, 0b111, 0b101, 0b111],
        [0b111, 0b101, 0b111, 0b001, 0b111],
    ]

    static let charPatterns: [Character: [UInt8]] = [
        "A": [0b111, 0b101, 0b111, 0b101, 0b101],
        "C": [0b111, 0b100, 0b100, 0b100, 0b111],
        "I": [0b111, 0b010, 0b010, 0b010, 0b111],
        "K": [0b101, 0b101, 0b110, 0b101, 0b101],
        "L": [0b100, 0b100, 0b100, 0b100, 0b111],
        "N": [0b101, 0b111, 0b111, 0b101, 0b101],
        "O": [0b111, 0b101, 0b101, 0b101, 0b111],
        "P": [0b111, 0b101, 0b111, 0b100, 0b100],
        "R": [0b111, 0b101, 0b111, 0b110, 0b101],
        "S": [0b111, 0b100, 0b111, 0b001, 0b111],
        "T": [0b111, 0b010, 0b010, 0b010, 0b010],
        "U": [0b101, 0b101, 0b101, 0b101, 0b111],
        "W": [0b101, 0b101, 0b111, 0b111, 0b101],
        "Y": [0b101, 0b101, 0b111, 0b010, 0b010],
        "!": [0b010, 0b010, 0b010, 0b000, 0b010],
        " ": [0b000, 0b000, 0b000, 0b000, 0b000],
    ]
}
