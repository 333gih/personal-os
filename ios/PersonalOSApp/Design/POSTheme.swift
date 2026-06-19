import SwiftUI

enum POSTheme {
    static let background = Color(red: 249 / 255, green: 247 / 255, blue: 242 / 255)
    static let card = Color(red: 255 / 255, green: 253 / 255, blue: 250 / 255)
    static let ink = Color(red: 38 / 255, green: 32 / 255, blue: 28 / 255)
    static let foreground = ink
    static let primary = Color(red: 176 / 255, green: 52 / 255, blue: 68 / 255)
    static let primaryDark = Color(red: 140 / 255, green: 38 / 255, blue: 52 / 255)
    static let muted = Color(red: 118 / 255, green: 108 / 255, blue: 98 / 255)
    static let border = Color(red: 228 / 255, green: 220 / 255, blue: 210 / 255)
    static let paperLine = Color(red: 220 / 255, green: 210 / 255, blue: 198 / 255)
    static let paperHighlight = Color.white
    static let paperShadow = Color(red: 90 / 255, green: 70 / 255, blue: 55 / 255)
    static let success = Color(red: 46 / 255, green: 120 / 255, blue: 78 / 255)
    static let successBg = Color(red: 232 / 255, green: 246 / 255, blue: 236 / 255)
    static let focus = Color(red: 58 / 255, green: 102 / 255, blue: 88 / 255)

    static let cardRadius: CGFloat = 20
    static let tabBarHeight: CGFloat = 60
}

extension Font {
    static func posDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func posLabel(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium)
    }

    static func posCaps(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .semibold)
    }
}
