import AppKit

enum RRColor {
    static let baseBackground = NSColor(calibratedRed: 32 / 255, green: 29 / 255, blue: 29 / 255, alpha: 1)
    static let elevatedBackground = NSColor(calibratedRed: 48 / 255, green: 44 / 255, blue: 44 / 255, alpha: 1)
    static let primaryText = NSColor(calibratedRed: 253 / 255, green: 252 / 255, blue: 252 / 255, alpha: 1)
    static let secondaryText = NSColor(calibratedRed: 154 / 255, green: 152 / 255, blue: 152 / 255, alpha: 1)
    static let accentBlue = NSColor.systemBlue
    static let success = NSColor.systemGreen
    static let warning = NSColor.systemOrange
    static let danger = NSColor.systemRed
    static let border = NSColor(calibratedWhite: 1, alpha: 0.12)
    static let noteNormal = NSColor.systemBlue
    static let noteLong = NSColor.systemGreen
    static let noteSpecial = NSColor.systemOrange
}

enum RRMetrics {
    static let unit: CGFloat = 8
    static let cornerRadius: CGFloat = 4
    static let inputRadius: CGFloat = 6
}

enum RRTypography {
    static func heading() -> NSFont {
        NSFont.monospacedSystemFont(ofSize: 28, weight: .bold)
    }

    static func section() -> NSFont {
        NSFont.monospacedSystemFont(ofSize: 15, weight: .semibold)
    }

    static func body() -> NSFont {
        NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    }

    static func caption() -> NSFont {
        NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    }
}

extension NSView {
    func applyCardStyle() {
        wantsLayer = true
        layer?.backgroundColor = RRColor.elevatedBackground.cgColor
        layer?.cornerRadius = RRMetrics.cornerRadius
        layer?.borderWidth = 1
        layer?.borderColor = RRColor.border.cgColor
    }
}
