import ImageIO
import UIKit

/// The art the app saved for a show in the App Group (widgets can't download). Nil when there is none yet; the
/// widgets look right without it.
enum WidgetArtwork {
    /// The saved hero art, at full size, or drawn down so its long side is at most `maxPixel` (the small widget needn't
    /// carry a 1000 px image into the widget's archive).
    static func image(showID: String, maxPixel: Int? = nil) -> UIImage? {
        guard let container = SnapshotStore.container else { return nil }
        return load(SnapshotStore.artworkURL(showID: showID, in: container), maxPixel: maxPixel)
    }

    /// The small posters for the rows after the hero, drawn down to `maxPixel`, by show ID.
    static func posters(for drops: some Sequence<Drop>, maxPixel: Int) -> [String: UIImage] {
        guard let container = SnapshotStore.container else { return [:] }
        var posters: [String: UIImage] = [:]
        for drop in drops where posters[drop.showID] == nil {
            posters[drop.showID] = load(SnapshotStore.posterURL(showID: drop.showID, in: container), maxPixel: maxPixel)
        }
        return posters
    }

    private static func load(_ url: URL, maxPixel: Int?) -> UIImage? {
        guard let maxPixel else { return UIImage(contentsOfFile: url.path(percentEncoded: false)) }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceCreateThumbnailWithTransform: true,
                                        kCGImageSourceThumbnailMaxPixelSize: maxPixel]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}
