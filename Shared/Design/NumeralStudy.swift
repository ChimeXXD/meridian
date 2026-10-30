import SwiftUI
import UIKit

/// The three numeral directions in UI-BRIEF §3. Chime picks one; the others are then deleted
/// and `EnvironmentValues.numeralStudy` defaults to the winner.
enum NumeralStudy: String, CaseIterable, Sendable {
    case system, mono, serif
    /// Thin serif over artwork, from Chime's Insight Timer pick (D-37).
    case night
    /// Large thin sans over Liquid Glass, for direction B (Apple Weather's temperatures).
    case glass

    var title: String {
        switch self {
        case .system: "A · System"
        case .mono: "B · Mono"
        case .serif: "C · Serif"
        case .night: "Night"
        case .glass: "Glass"
        }
    }

    var summary: String {
        switch self {
        case .system: "SF Pro Heavy, tabular digits, no accent"
        case .mono: "SF Mono Medium, lime accent"
        case .serif: "New York Semibold, tabular digits, warm yellow accent"
        case .night: "New York Light over artwork, white"
        case .glass: "SF Pro Thin over glass, white"
        }
    }

    var design: Font.Design {
        switch self {
        case .system, .glass: .default
        case .mono: .monospaced
        case .serif, .night: .serif
        }
    }

    var weight: Font.Weight {
        switch self {
        case .system: .heavy
        case .mono: .medium
        case .serif: .semibold
        case .night: .light
        case .glass: .thin
        }
    }

    /// Countdown tint and controls. Never used for status.
    var accentInk: UIColor {
        switch self {
        case .system, .night, .glass: .label
        case .mono: Tokens.dynamic(light: 0x3F6B0A, dark: 0xC6F432)
        case .serif: Tokens.dynamic(light: 0x8A6100, dark: 0xFFC940)
        }
    }

    var accent: Color { Color(uiColor: accentInk) }

    /// Numerals at a point size, with tabular digits so a ticking timer never jitters.
    func font(size: CGFloat) -> Font {
        .system(size: size, weight: weight, design: design).monospacedDigit()
    }
}

extension EnvironmentValues {
    @Entry var numeralStudy: NumeralStudy = .system
}
