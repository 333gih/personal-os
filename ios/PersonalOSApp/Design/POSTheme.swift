import SwiftUI

enum POSTheme {
    static let background = Color(red: 249 / 255, green: 247 / 255, blue: 242 / 255)
    static let card = Color(red: 252 / 255, green: 250 / 255, blue: 246 / 255)
    static let primary = Color(red: 255 / 255, green: 77 / 255, blue: 109 / 255)
    static let primaryDark = Color(red: 165 / 255, green: 28 / 255, blue: 48 / 255)
    static let foreground = Color(red: 28 / 255, green: 25 / 255, blue: 23 / 255)
    static let muted = Color(red: 120 / 255, green: 113 / 255, blue: 108 / 255)
    static let border = Color(red: 230 / 255, green: 225 / 255, blue: 218 / 255)
    static let success = Color(red: 21 / 255, green: 128 / 255, blue: 61 / 255)
    static let successBg = Color(red: 220 / 255, green: 252 / 255, blue: 231 / 255)

    static let cardRadius: CGFloat = 24
    static let tabBarHeight: CGFloat = 60
}

extension Font {
    static func posDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func posLabel(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold)
    }
}
