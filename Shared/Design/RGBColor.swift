import SwiftUI

/// An sRGB colour with the maths the artwork palette needs: HSB conversion and WCAG contrast.
struct RGBColor: Hashable, Sendable {
    var r: Double
    var g: Double
    var b: Double

    init(r: Double, g: Double, b: Double) {
        (self.r, self.g, self.b) = (r, g, b)
    }

    /// `hue` in degrees (0–360), `saturation` and `brightness` in 0–1.
    init(hue: Double, saturation: Double, brightness: Double) {
        let h = (hue.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / 60
        let c = brightness * saturation
        let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c
        let (r, g, b): (Double, Double, Double) = switch Int(h) {
        case 0: (c, x, 0)
        case 1: (x, c, 0)
        case 2: (0, c, x)
        case 3: (0, x, c)
        case 4: (x, 0, c)
        default: (c, 0, x)
        }
        self.init(r: r + m, g: g + m, b: b + m)
    }

    var brightness: Double { max(r, g, b) }

    var saturation: Double {
        let high = max(r, g, b)
        return high == 0 ? 0 : (high - min(r, g, b)) / high
    }

    /// Degrees, 0–360; 0 for greys.
    var hue: Double {
        let high = max(r, g, b), delta = high - min(r, g, b)
        guard delta > 0 else { return 0 }
        let sector: Double = switch high {
        case r: ((g - b) / delta).truncatingRemainder(dividingBy: 6)
        case g: (b - r) / delta + 2
        default: (r - g) / delta + 4
        }
        return (sector * 60 + 360).truncatingRemainder(dividingBy: 360)
    }

    /// WCAG 2.x relative luminance.
    var luminance: Double {
        func channel(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    func contrast(with other: RGBColor) -> Double {
        let (high, low) = (max(luminance, other.luminance), min(luminance, other.luminance))
        return (high + 0.05) / (low + 0.05)
    }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b) }
}
