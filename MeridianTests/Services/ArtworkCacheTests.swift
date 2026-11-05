import Foundation
import Testing
import UIKit
@testable import Meridian

/// Art the phone already decoded is drawn on a page's first frame, not faded in after an actor hop (EA-3): the
/// loader's cache can be read synchronously, by URL and size.
@Suite("Artwork cache")
struct ArtworkCacheTests {
    /// A tiny PNG on disk; URLSession loads file URLs like any other, so no network or committed art is needed.
    private static func pngURL() throws -> URL {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 6)).image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 6))
        }
        let url = URL.temporaryDirectory.appendingPathComponent("artwork-cache-\(UUID().uuidString).png")
        try #require(image.pngData()).write(to: url)
        return url
    }

    @Test("art not loaded yet isn't in the cache")
    func missBeforeLoad() throws {
        #expect(ArtworkLoader.cached(try Self.pngURL(), maxPixel: 300) == nil)
    }

    @Test("once loaded, the same URL and size are there at once; another size isn't")
    func hitAfterLoad() async throws {
        let url = try Self.pngURL()
        _ = try await ArtworkLoader.shared.load(url, maxPixel: 300)
        #expect(ArtworkLoader.cached(url, maxPixel: 300) != nil)
        #expect(ArtworkLoader.cached(url, maxPixel: 1_920) == nil)
    }
}
