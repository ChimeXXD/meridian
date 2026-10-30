import CoreGraphics
import Foundation

/// Colours taken from a show's artwork (Chime's picks: Insight Timer, Plex, Duolingo). `base` is a deep tone of the
/// artwork's hue for page and card backgrounds, always dark enough for white text at 7:1; `accent` is a pale tint
/// of the same hue for small highlights, at least 4.5:1 on `base`.
struct ArtworkPalette: Hashable, Sendable {
    let base: RGBColor
    let accent: RGBColor

    /// Before artwork loads, or when there is none.
    static let neutral = ArtworkPalette(hue: 0, saturation: 0)

    private static let white = RGBColor(r: 1, g: 1, b: 1)

    init(hue: Double, saturation: Double) {
        let s = min(saturation, 0.65)
        var brightness = 0.32
        var base = RGBColor(hue: hue, saturation: s, brightness: brightness)
        while Self.white.contrast(with: base) < 7.5, brightness > 0.04 {
            brightness -= 0.02
            base = RGBColor(hue: hue, saturation: s, brightness: brightness)
        }
        self.base = base
        accent = RGBColor(hue: hue, saturation: min(s, 0.5) * 0.45, brightness: 1)
    }

    /// Samples the image at 24 × 24. Vivid pixels count for more than grey ones, so a small coloured subject on a
    /// grey set still sets the tone, and a grey image stays neutral instead of getting an invented colour.
    init(image: CGImage) {
        let side = 24
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                                          bytesPerRow: side * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { self = .neutral; return }

        var (x, y, weights, saturation) = (0.0, 0.0, 0.0, 0.0)
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Double(pixels[i + 3]) / 255
            guard alpha > 0.5 else { continue }
            let pixel = RGBColor(r: Double(pixels[i]) / 255 / alpha, g: Double(pixels[i + 1]) / 255 / alpha,
                                 b: Double(pixels[i + 2]) / 255 / alpha)
            let weight = pixel.saturation * pixel.brightness + 0.02
            let angle = pixel.hue * .pi / 180
            x += cos(angle) * weight
            y += sin(angle) * weight
            saturation += pixel.saturation * weight
            weights += weight
        }
        guard weights > 0 else { self = .neutral; return }
        let hue = (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        self.init(hue: hue, saturation: saturation / weights)
    }
}
