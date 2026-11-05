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

    /// Decoded art by URL and size. NSCache evicts under memory pressure, where a dictionary of decoded images only
    /// grows, and it's thread-safe, so a view can peek at it on its first frame without waiting on this actor (EA-3).
    private final class Cache: @unchecked Sendable {
        private final class Box { let loaded: Loaded; init(_ loaded: Loaded) { self.loaded = loaded } }
        private let storage: NSCache<NSString, Box> = {
            let cache = NSCache<NSString, Box>()
            cache.countLimit = 60
            return cache
        }()

        subscript(key: String) -> Loaded? {
            get { storage.object(forKey: key as NSString)?.loaded }
            set { if let newValue { storage.setObject(Box(newValue), forKey: key as NSString) } }
        }
    }

    private let session: URLSession
    private nonisolated let cache = Cache()
    private var inFlight: [String: Task<Loaded, Error>] = [:]

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 16 << 20, diskCapacity: 256 << 20,
                                          directory: URL.cachesDirectory.appendingPathComponent("Artwork"))
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        // Wikimedia, which serves the service logos (D-44), asks every app to name itself.
        configuration.httpAdditionalHeaders = ["User-Agent": "Meridian/1.0 (https://github.com/ChimeXXD/meridian)"]
        session = URLSession(configuration: configuration)
    }

    /// Art already decoded at this size, read at once: a page opened on art the viewer just saw draws it on its first
    /// frame, instead of the night base and then a fade (EA-3).
    nonisolated static func cached(_ url: URL, maxPixel: Int) -> Loaded? {
        shared.cache[key(url, maxPixel: maxPixel)]
    }

    private nonisolated static func key(_ url: URL, maxPixel: Int) -> String { "\(url.absoluteString)@\(maxPixel)" }

    /// `maxPixel` is the longest side to decode, in pixels.
    func load(_ url: URL, maxPixel: Int) async throws -> Loaded {
        let key = Self.key(url, maxPixel: maxPixel)
        if let loaded = cache[key] { return loaded }
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
        cache[key] = loaded
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
