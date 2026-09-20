import AppKit

/// The app's menu bar glyph: two paddles and a ball.
///
/// One factory, because the status item and the popover header draw the same
/// mark at different sizes. Drawn rather than shipped as an asset: SwiftPM does
/// not compile asset catalogues.
enum StatusItemIcon {
    /// Brandbook 8.1: 18 x 18pt, template, in a `.squareLength` status item.
    /// The header uses the same glyph at 16pt.
    static func make(size: CGFloat = 18) -> NSImage {
        // The original was drawn against an 18pt box, so the numbers below are
        // that geometry expressed in units of it.
        let unit = size / 18

        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: NSRect(x: 3 * unit, y: 4 * unit, width: 12 * unit, height: 2 * unit),
                         xRadius: 1 * unit, yRadius: 1 * unit).fill()
            NSBezierPath(ovalIn: NSRect(x: 7.5 * unit, y: 8 * unit, width: 3 * unit, height: 3 * unit)).fill()
            NSBezierPath(roundedRect: NSRect(x: 1 * unit, y: 13 * unit, width: 12 * unit, height: 2 * unit),
                         xRadius: 1 * unit, yRadius: 1 * unit).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
