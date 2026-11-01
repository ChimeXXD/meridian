import ImageIO
import UIKit

/// Downloads show artwork at runtime (D-37), shrinks it on the phone, and works out its palette.
/// Originals can be 11K wide, so images are decoded straight to the size they're shown at.
actor ArtworkLoader {
    struct Loaded: Sendable {
        let image: UIImage
        let palette: ArtworkPalette
    }

    static let shared = ArtworkLoader()

    /// NSCache needs a class; it evicts under memory pressure, where a dictionary of decoded images only grows.
    private final class Box { let loaded: Loaded; init(_ loaded: Loaded) { self.loaded = loaded } }

    private let session: URLSession
    private let cache: NSCache<NSString, Box> = {
        let cache = NSCache<NSString, Box>()
        cache.countLimit = 60
        return cache
    }()
    private var inFlight: [String: Task<Loaded, Error>] = [:]

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 16 << 20, diskCapacity: 256 << 20,
                                          directory: URL.cachesDirectory.appendingPathComponent("Artwork"))
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        // Wikimedia, which serves the service logos (D-44), asks every app to name itself.
        configuration.httpAdditionalHeaders = ["User-Agent": "Airstamp/1.0 (https://github.com/ChimeXXD/next-episode)"]
        session = URLSession(configuration: configuration)
    }

    /// `maxPixel` is the longest side to decode, in pixels.
    func load(_ url: URL, maxPixel: Int) async throws -> Loaded {
        let key = "\(url.absoluteString)@\(maxPixel)"
        if let box = cache.object(forKey: key as NSString) { return box.loaded }
        if let task = inFlight[key] { return try await task.value }
        let session = session
        let task = Task<Loaded, Error> {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode ?? 200 < 300,
                  let image = Self.downsample(data, maxPixel: maxPixel) else { throw URLError(.cannotDecodeContentData) }
            return Loaded(image: UIImage(cgImage: image), palette: ArtworkPalette(image: image))
        }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        let loaded = try await task.value
        cache.setObject(Box(loaded), forKey: key as NSString)
        return loaded
    }

    private static func downsample(_ data: Data, maxPixel: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
