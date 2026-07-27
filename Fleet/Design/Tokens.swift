import SwiftUI

/// Color palette from Fleet-设计稿V1.md.
enum FleetColor {
    static let sidebarBackground = Color(hex: 0x04342C)
    static let sidebarAccent = Color(hex: 0x0F6E56)
    static let mint = Color(hex: 0x5DCAA5)

    static let claudeCardBackground = Color(hex: 0xE1F5EE)
    static let codexCardBackground = Color(hex: 0xEEEDFE)
    static let codexCardText = Color(hex: 0x3C3489)

    static let idle = Color(hex: 0x888780)
    static let expired = Color(hex: 0xEF9F27)
    static let expiredText = Color(hex: 0x854F0B)
}

enum FleetFont {
    static func brandTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, design: .monospaced)
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
