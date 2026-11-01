import ImageIO
import UIKit

/// The art the app saved for a show in the App Group (widgets can't download). Nil when there is none yet; the
/// widgets look right without it.
enum WidgetArtwork {
    /// The saved art, at full size, or drawn down so its long side is at most `maxPixel` (a row's thumbnail needn't
    /// carry a 1000 px image into the widget's archive).
    static func image(showID: String, maxPixel: Int? = nil) -> UIImage? {
        guard let container = SnapshotStore.container else { return nil }
        let url = SnapshotStore.artworkURL(showID: showID, in: container)
        guard let maxPixel else { return UIImage(contentsOfFile: url.path(percentEncoded: false)) }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceCreateThumbnailWithTransform: true,
                                        kCGImageSourceThumbnailMaxPixelSize: maxPixel]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }

    /// The first drop's art at full size, for the hero; the others' at `rowPixel`, for their row thumbnails, or not
    /// at all when `rowPixel` is nil (the medium widget's rows have none).
    static func images(for drops: [Drop], rowPixel: Int?) -> [String: UIImage] {
        var images: [String: UIImage] = [:]
        for (index, drop) in drops.enumerated() where images[drop.showID] == nil {
            if index == 0 {
                images[drop.showID] = image(showID: drop.showID)
            } else if let rowPixel {
                images[drop.showID] = image(showID: drop.showID, maxPixel: rowPixel)
            }
        }
        return images
    }
}
