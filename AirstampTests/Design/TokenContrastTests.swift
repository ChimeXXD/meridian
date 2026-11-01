import Testing
import UIKit
@testable import Airstamp

/// Status inks and accents are used as text, so they must reach WCAG AA (4.5:1) on the surfaces they sit on,
/// including inside a chip, where the background is the ink at `Tokens.chipFillOpacity` over the card.
@Suite("Token contrast")
struct TokenContrastTests {
    static let inks: [(String, UIColor)] = [
        ("exact", Tokens.Ink.exact), ("estimated", Tokens.Ink.estimated), ("adjusted", Tokens.Ink.adjusted),
        ("dateOnly", Tokens.Ink.dateOnly), ("delayed", Tokens.Ink.delayed), ("noStream", Tokens.Ink.noStream),
    ] + NumeralStudy.allCases.map { ("accent.\($0.rawValue)", $0.accentInk) }

    static let styles: [UIUserInterfaceStyle] = [.light, .dark]

    @Test("every ink passes AA on the background, the card and its own chip fill", arguments: inks.map(\.0))
    func passesAA(name: String) throws {
        let ink = try #require(Self.inks.first { $0.0 == name }?.1)
        for style in Self.styles {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let text = RGB(ink.resolvedColor(with: traits))
            let card = RGB(UIColor.secondarySystemGroupedBackground.resolvedColor(with: traits))
            let surfaces = [
                ("background", RGB(UIColor.systemGroupedBackground.resolvedColor(with: traits))),
                ("card", card),
                ("chip", card.blended(with: text, amount: Tokens.chipFillOpacity)),
            ]
            for (surface, color) in surfaces {
                let ratio = text.contrast(with: color)
                #expect(ratio >= 4.5, "\(name) on \(surface) in \(style == .dark ? "dark" : "light") mode is \(ratio)")
            }
        }
    }

    /// Meridian Gold is drawn only on the night bases, which stay dark in light mode too (D-53).
    @Test("gold passes AA on the widget and Live Activity night")
    func goldOnNight() {
        let gold = RGB(Tokens.gold)
        for (surface, base) in [("widget", WidgetInk.base), ("Live Activity", LiveActivityInk.base)] {
            let ratio = gold.contrast(with: RGB(UIColor(base)))
            #expect(ratio >= 4.5, "gold on the \(surface) night is \(ratio)")
        }
    }
}

private struct RGB {
    var r: Double, g: Double, b: Double

    init(_ color: UIColor) {
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        (self.r, self.g, self.b) = (Double(r), Double(g), Double(b))
    }

    init(r: Double, g: Double, b: Double) { (self.r, self.g, self.b) = (r, g, b) }

    func blended(with top: RGB, amount: Double) -> RGB {
        RGB(r: r + (top.r - r) * amount, g: g + (top.g - g) * amount, b: b + (top.b - b) * amount)
    }

    /// WCAG 2.x relative luminance.
    var luminance: Double {
        func channel(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    func contrast(with other: RGB) -> Double {
        let (hi, lo) = (max(luminance, other.luminance), min(luminance, other.luminance))
        return (hi + 0.05) / (lo + 0.05)
    }
}
