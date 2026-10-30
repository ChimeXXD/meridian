import SwiftUI
import UIKit

/// Design tokens from `docs/design/UI-BRIEF.md` §2. Neutrals are system colours; status inks have fixed
/// meanings and are dark enough in light mode to pass WCAG AA as text (checked by `TokenContrastTests`).
enum Tokens {
    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 14
        static let sheet: CGFloat = 20
        static let widget: CGFloat = 22
    }

    /// Chip backgrounds are the chip's ink at this opacity.
    static let chipFillOpacity: CGFloat = 0.14

    /// Status inks. Each is used next to a word and a glyph, never alone.
    enum Ink {
        static let exact = dynamic(light: 0x17692A, dark: 0x5BE38A)
        static let estimated = dynamic(light: 0x1F5FCC, dark: 0x8AB0FF)
        static let adjusted = dynamic(light: 0x7B3FC4, dark: 0xC9A6FF)
        static let dateOnly = dynamic(light: 0x5E5E66, dark: 0xA8A8B0)
        static let delayed = dynamic(light: 0x96440A, dark: 0xFDBA74)
        static let noStream = dynamic(light: 0xB01F1F, dark: 0xFF8A80)
    }

    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)

    static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? rgb(dark) : rgb(light) }
    }

    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
