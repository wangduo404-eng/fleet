import SwiftUI

/// Color palette from Fleet-设计稿V1.md.
enum FleetColor {
    static let sidebarBackground = Color(hex: 0x04342C)
    static let sidebarAccent = Color(hex: 0x0F6E56)
    static let mint = Color(hex: 0x5DCAA5)

    /// Anthropic's brand terracotta/orange.
    static let claudeAccent = Color(hex: 0xD97757)
    static let claudeCardBackground = Color(hex: 0xF7E9E2)
    static let claudeCardText = Color(hex: 0x7A3B22)

    /// Deliberately NOT OpenAI's official #10A37F green — verified that's
    /// still their real brand color (2026-07-28 web search), but Fleet's
    /// own "active" status dot is already a mint-green (`mint` above), so
    /// a same-family green for the Codex engine made "this is Codex" and
    /// "this is active" blend together. Blue reads clearly distinct from
    /// both Claude's orange and the active indicator.
    static let codexAccent = Color(hex: 0x2F6FE4)
    static let codexCardBackground = Color(hex: 0xE7EEFB)
    static let codexCardText = Color(hex: 0x1C3D6E)

    static let idle = Color(hex: 0x888780)
    static let expired = Color(hex: 0xEF9F27)
    static let expiredText = Color(hex: 0x854F0B)
}

extension Engine {
    /// Solid brand-color swatch used for the engine's color block/icon.
    var accentColor: Color {
        switch self {
        case .claudeCode: return FleetColor.claudeAccent
        case .codex: return FleetColor.codexAccent
        }
    }

    var cardBackground: Color {
        switch self {
        case .claudeCode: return FleetColor.claudeCardBackground
        case .codex: return FleetColor.codexCardBackground
        }
    }

    var cardTextColor: Color {
        switch self {
        case .claudeCode: return FleetColor.claudeCardText
        case .codex: return FleetColor.codexCardText
        }
    }

    var symbolName: String {
        switch self {
        case .claudeCode: return "bubble.left.and.bubble.right"
        case .codex: return "terminal"
        }
    }
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
