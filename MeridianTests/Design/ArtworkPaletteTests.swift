import CoreGraphics
import Testing
@testable import Meridian

/// The page colour behind white text comes from the artwork (Insight Timer, Plex, Duolingo picks), so it must
/// keep the artwork's hue and still be dark enough to read on, whatever the art looks like.
@Suite("Artwork palette")
struct ArtworkPaletteTests {
    static func image(_ fill: (CGContext) -> Void) -> CGImage {
        let context = CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        fill(context)
        return context.makeImage()!
    }

    static func solid(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGImage {
        image { $0.setFillColor(red: r, green: g, blue: b, alpha: 1); $0.fill(CGRect(x: 0, y: 0, width: 64, height: 64)) }
    }

    static let white = RGBColor(r: 1, g: 1, b: 1)

    @Test("white text on the base colour passes 7:1 for any artwork", arguments: [
        ("mustard", solid(0.85, 0.65, 0.10)), ("white", solid(1, 1, 1)), ("black", solid(0, 0, 0)),
        ("teal", solid(0.20, 0.55, 0.55)), ("grey", solid(0.5, 0.5, 0.5)), ("neon green", solid(0.2, 1, 0.1)),
    ])
    func readable(name: String, art: CGImage) {
        let palette = ArtworkPalette(image: art)
        #expect(Self.white.contrast(with: palette.base) >= 7, "\(name): \(Self.white.contrast(with: palette.base))")
        #expect(palette.accent.contrast(with: palette.base) >= 4.5, "\(name) accent: \(palette.accent.contrast(with: palette.base))")
    }

    @Test("the base keeps the artwork's hue", arguments: [
        ("mustard", solid(0.85, 0.65, 0.10), 43.0), ("teal", solid(0.20, 0.55, 0.55), 180.0), ("maroon", solid(0.55, 0.08, 0.15), 351.0),
    ])
    func keepsHue(name: String, art: CGImage, hue: Double) {
        let base = ArtworkPalette(image: art).base
        let distance = abs(((base.hue - hue + 540).truncatingRemainder(dividingBy: 360)) - 180)
        #expect(distance < 12, "\(name): hue \(base.hue), expected about \(hue)")
        #expect(base.saturation > 0.2)
    }

    @Test("teal and orange art gives teal or orange, not the olive between them (Silo's poster)")
    func complementaryHuesDontMix() {
        let art = Self.image { context in
            context.setFillColor(red: 0.10, green: 0.50, blue: 0.55, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 40))
            context.setFillColor(red: 0.90, green: 0.50, blue: 0.10, alpha: 1)
            context.fill(CGRect(x: 0, y: 40, width: 64, height: 24))
        }
        let hue = ArtworkPalette(image: art).base.hue
        let distance = { (target: Double) in abs(((hue - target + 540).truncatingRemainder(dividingBy: 360)) - 180) }
        #expect(distance(185) < 15 || distance(30) < 15, "hue \(hue) is neither teal nor orange")
    }

    @Test("a small muted blue subject on grey gives blue, not the red hue greys report")
    func greysDontVoteForRed() {
        let art = Self.image { context in
            context.setFillColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
            context.setFillColor(red: 0.35, green: 0.40, blue: 0.50, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 4))
        }
        let hue = ArtworkPalette(image: art).base.hue
        #expect(abs(((hue - 220 + 540).truncatingRemainder(dividingBy: 360)) - 180) < 20, "hue \(hue)")
    }

    @Test("grey artwork gives a neutral base, not an invented colour")
    func greyStaysNeutral() {
        #expect(ArtworkPalette(image: Self.solid(0.5, 0.5, 0.5)).base.saturation < 0.05)
    }

    @Test("colourful pixels outweigh a large grey area, so a small red subject still sets the tone")
    func saturatedPixelsWin() {
        let art = Self.image { context in
            context.setFillColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
            context.setFillColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 16))  // a quarter of the image
        }
        let base = ArtworkPalette(image: art).base
        #expect(base.hue < 15 || base.hue > 345, "hue \(base.hue)")
    }
}
