import CoreGraphics
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// The art a widget shows (D4-1, D-46): a JPEG at most 1000 px on its long side, near the 1014 px a medium or large
/// widget is wide at 3x, and as a rule under 100 KB, saved in the App Group because widgets can't download. Three
/// decoded at once are about 7 MB, well inside a widget's memory. Made on the phone from the art the app already loads
/// (D-37); it is never committed to the repo (CLAUDE.md rule 9).
enum WidgetArt {
    static let maxPixel = 1_000
    static let targetBytes = 100_000

    /// Downloads art through the app's artwork cache (heroes and rows may have loaded it already) and shrinks it.
    @Sendable static func fetch(_ url: URL) async -> Data? {
        guard let loaded = try? await ArtworkLoader.shared.load(url, maxPixel: maxPixel),
              let image = loaded.image.cgImage else { return nil }
        return jpeg(image)
    }

    /// The image as a JPEG no longer than `maxPixel` on either side, never upscaled. Steps the quality down until it
    /// fits `targetBytes`; returns the smallest try if none does.
    static func jpeg(_ image: CGImage) -> Data? {
        guard let image = scaled(image) else { return nil }
        var smallest: Data?
        for quality in [0.75, 0.6, 0.45] {
            guard let data = encode(image, quality: quality) else { return smallest }
            if data.count < targetBytes { return data }
            smallest = data
        }
        return smallest
    }

    private static func encode(_ image: CGImage, quality: Double) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
        else { return nil }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }

    /// Draws the image down so its long side is `maxPixel`; a smaller image is returned as it is.
    private static func scaled(_ image: CGImage) -> CGImage? {
        let longest = max(image.width, image.height)
        guard longest > maxPixel else { return image }
        let scale = Double(maxPixel) / Double(longest)
        let width = max(1, Int((Double(image.width) * scale).rounded()))
        let height = max(1, Int((Double(image.height) * scale).rounded()))
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
