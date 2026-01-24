import SwiftUI

/// Sane Apps Brand Color Palette
/// Reference: ~/SaneApps/meta/Brand/SaneApps-Brand-Guidelines.md
extension Color {
    // MARK: - SaneClip Accent

    /// Primary accent color for SaneClip - Clip Blue #4f8ffa
    static let clipBlue = Color(hex: 0x4f8ffa)

    /// Pinned items accent - Warning Orange #f59e0b
    static let pinnedOrange = Color(hex: 0xf59e0b)

    // MARK: - Brand Primary

    /// Navy - Logo background, dark surfaces #1a2744
    static let brandNavy = Color(hex: 0x1a2744)

    /// Deep Navy - Gradient endpoint #0d1525
    static let brandDeepNavy = Color(hex: 0x0d1525)

    /// Glowing Teal - Highlights, CTAs #5fa8d3
    static let brandTeal = Color(hex: 0x5fa8d3)

    /// Silver - Secondary elements #a8b4c4
    static let brandSilver = Color(hex: 0xa8b4c4)

    // MARK: - Surface Colors

    /// Void - Backgrounds #0a0a0a
    static let surfaceVoid = Color(hex: 0x0a0a0a)

    /// Carbon - Cards, elevated surfaces #141414
    static let surfaceCarbon = Color(hex: 0x141414)

    /// Smoke - Borders, dividers #222222
    static let surfaceSmoke = Color(hex: 0x222222)

    // MARK: - Text Colors

    /// Stone - Muted text (like .secondary) #888888
    static let textStone = Color(hex: 0x888888)

    /// Cloud - Primary text #e5e5e5
    static let textCloud = Color(hex: 0xe5e5e5)

    // MARK: - Semantic Colors

    /// Success green #22c55e
    static let semanticSuccess = Color(hex: 0x22c55e)

    /// Warning amber #f59e0b
    static let semanticWarning = Color(hex: 0xf59e0b)

    /// Error red #ef4444
    static let semanticError = Color(hex: 0xef4444)
}

// MARK: - Hex Initializer

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
