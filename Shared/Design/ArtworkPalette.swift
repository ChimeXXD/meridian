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
    /// Below this a pixel counts as grey: its hue is noise.
    private static let greySaturation = 0.05

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
    /// Hues are binned and the strongest band wins, so teal-and-orange art gives teal or orange rather than the
    /// olive an average of the two would invent.
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

        // 24 bands of 15°, each summing its pixels' weight, hue vector and saturation. Greys have no hue (RGBColor
        // reports 0, red), so they stay out of the bands and only dilute the saturation, whichever band wins.
        let bandCount = 24
        var bands = [(x: Double, y: Double, weight: Double, saturation: Double)](repeating: (0, 0, 0, 0), count: bandCount)
        var greyWeight = 0.0
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Double(pixels[i + 3]) / 255
            guard alpha > 0.5 else { continue }
            let pixel = RGBColor(r: Double(pixels[i]) / 255 / alpha, g: Double(pixels[i + 1]) / 255 / alpha,
                                 b: Double(pixels[i + 2]) / 255 / alpha)
            let weight = pixel.saturation * pixel.brightness + 0.02
            guard pixel.saturation >= Self.greySaturation else { greyWeight += weight; continue }
            let angle = pixel.hue * .pi / 180
            let band = min(Int(pixel.hue / 15), bandCount - 1)
            bands[band].x += cos(angle) * weight
            bands[band].y += sin(angle) * weight
            bands[band].weight += weight
            bands[band].saturation += pixel.saturation * weight
        }
        // The strongest band with its two neighbours (wrapping at 360°), then the mean hue inside that window only.
        let window = { (centre: Int) in [-1, 0, 1].map { bands[(centre + $0 + bandCount) % bandCount] } }
        let windowWeights = (0..<bandCount).map { window($0).map(\.weight).reduce(0, +) }
        guard let best = windowWeights.indices.max(by: { windowWeights[$0] < windowWeights[$1] }), windowWeights[best] > 0
        else { self = .neutral; return }
        let chosen = window(best)
        let (x, y) = (chosen.map(\.x).reduce(0, +), chosen.map(\.y).reduce(0, +))
        let hue = (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        self.init(hue: hue, saturation: chosen.map(\.saturation).reduce(0, +) / (windowWeights[best] + greyWeight))
    }
}
