import CoreGraphics
import Foundation
import Testing
import UIKit

/// A render with its art cut out, for the design system's galleries: the art's pixels are fully transparent, and
/// everything drawn over the art (fades, tags, text) stays, at its own opacity. The site places the show's real art
/// behind the PNG at the holes the manifest lists, and the browser composites it as the phone does. No artwork pixel
/// is ever in the PNG, so it is safe to commit (CLAUDE.md rule 9).
///
/// It needs no hook in the app's views. The same view is rendered with solid black art and with solid white art, and
/// each pixel is `art × (1 − a) + p` (source-over), so `a = 1 − (white − black)` and the premultiplied colour `p` is
/// the black render. A third render with mid-grey art checks the blend really is linear, so the composite is right.
struct ArtMatte {
    let width: Int
    let height: Int
    /// Premultiplied sRGB RGBA, top row first.
    private(set) var pixels: [UInt8]
    /// The largest gap, in 8-bit steps, between the grey render and what the black and white ones predict.
    let linearityError: Int

    static let black = solid(0)
    static let white = solid(255)
    static let grey = solid(128)

    /// A tiny solid image: scaled to fill any frame, it stays one flat colour.
    static func solid(_ level: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.preferredRange = .standard
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).image { context in
            UIColor(white: CGFloat(level) / 255, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    /// Renders the view with each solid fill and pulls the art out. A countdown that ticks between renders would
    /// differ for reasons other than the art, so the black render is repeated and the set retried until both match.
    @MainActor
    static func cut(_ render: (UIImage) throws -> UIImage) throws -> ArtMatte {
        for _ in 0..<4 {
            let black = try Bitmap(try render(Self.black))
            let white = try Bitmap(try render(Self.white))
            let grey = try Bitmap(try render(Self.grey))
            let again = try Bitmap(try render(Self.black))
            if black.bytes == again.bytes { return try ArtMatte(black: black, white: white, grey: grey) }
        }
        throw UnstableRender()
    }

    /// The render differed between passes every time, so its art can't be pulled out.
    struct UnstableRender: Error, CustomStringConvertible {
        var description: String { "the render kept changing between passes" }
    }

    private init(black: Bitmap, white: Bitmap, grey: Bitmap) throws {
        try #require(black.width == white.width && black.height == white.height && grey.width == black.width
                     && grey.height == black.height)
        (width, height) = (black.width, black.height)
        var out = [UInt8](repeating: 0, count: black.bytes.count)
        var worst = 0
        for i in stride(from: 0, to: out.count, by: 4) {
            var sum = 0
            for c in 0..<3 {
                let b = Int(black.bytes[i + c]), w = Int(white.bytes[i + c]), g = Int(grey.bytes[i + c])
                sum += max(0, w - b)
                worst = max(worst, abs(g - (b + (w - b) * 128 / 255)))
            }
            // The render's own alpha less the art's share: a pixel the view leaves clear stays clear.
            let alpha = max(0, Int(black.bytes[i + 3]) - min(255, (sum + 1) / 3))
            out[i + 3] = UInt8(alpha)
            for c in 0..<3 { out[i + c] = min(black.bytes[i + c], UInt8(alpha)) }
        }
        pixels = out
        linearityError = worst
    }

    func alpha(_ x: Int, _ y: Int) -> UInt8 { pixels[(y * width + x) * 4 + 3] }

    var png: Data {
        get throws {
            let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
            var copy = pixels
            let image = try copy.withUnsafeMutableBytes { buffer in
                let context = try #require(CGContext(data: buffer.baseAddress, width: width, height: height,
                                                     bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                return try #require(context.makeImage())
            }
            return try #require(UIImage(cgImage: image).pngData())
        }
    }

    /// The pixel bounds of each connected patch (4-neighbour) that is more than half see-through, top to bottom.
    func clearPatches() -> [CGRect] {
        var seen = [Bool](repeating: false, count: width * height)
        var patches: [CGRect] = []
        for start in 0..<(width * height) where !seen[start] && pixels[start * 4 + 3] < 128 {
            var stack = [start]
            seen[start] = true
            var (minX, minY, maxX, maxY) = (width, height, 0, 0)
            while let index = stack.popLast() {
                let x = index % width, y = index / width
                (minX, minY, maxX, maxY) = (min(minX, x), min(minY, y), max(maxX, x), max(maxY, y))
                for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
                where nx >= 0 && ny >= 0 && nx < width && ny < height {
                    let next = ny * width + nx
                    if !seen[next] && pixels[next * 4 + 3] < 128 { seen[next] = true; stack.append(next) }
                }
            }
            patches.append(CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))
        }
        return patches.sorted { ($0.minY, $0.minX) < ($1.minY, $1.minX) }
    }

    /// How many pixels let anything through outside every hole (grown by a pixel for anti-aliased edges). Zero means
    /// the manifest accounts for all the art.
    func strayPixels(outside holes: [CGRect]) -> Int {
        let grown = holes.map { $0.insetBy(dx: -1, dy: -1) }
        var count = 0
        for y in 0..<height {
            for x in 0..<width where alpha(x, y) < 255 {
                let point = CGPoint(x: Double(x) + 0.5, y: Double(y) + 0.5)
                if !grown.contains(where: { $0.contains(point) }) { count += 1 }
            }
        }
        return count
    }

    /// The least opaque pixel in a hole: 0 means the art shows through fully somewhere in it.
    func minimumAlpha(in rect: CGRect) -> UInt8 {
        var least: UInt8 = 255
        let box = rect.integral.intersection(CGRect(x: 0, y: 0, width: width, height: height))
        for y in Int(box.minY)..<Int(box.maxY) {
            for x in Int(box.minX)..<Int(box.maxX) { least = min(least, alpha(x, y)) }
        }
        return least
    }
}

/// A render's pixels as 8-bit premultiplied sRGB, top row first.
private struct Bitmap {
    let width: Int
    let height: Int
    let bytes: [UInt8]

    init(_ image: UIImage) throws {
        let cgImage = try #require(image.cgImage)
        let (w, h) = (cgImage.width, cgImage.height)
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        var buffer = [UInt8](repeating: 0, count: w * h * 4)
        try buffer.withUnsafeMutableBytes { raw in
            let context = try #require(CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                                 bytesPerRow: w * 4, space: space,
                                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        (width, height, bytes) = (w, h, buffer)
    }
}
