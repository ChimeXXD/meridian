import UIKit

/// The small art the app saved for a show in the App Group (widgets can't download). Nil when there is none yet; the
/// widgets look right without it.
enum WidgetArtwork {
    static func image(showID: String) -> UIImage? {
        guard let container = SnapshotStore.container else { return nil }
        let url = SnapshotStore.artworkURL(showID: showID, in: container)
        return UIImage(contentsOfFile: url.path(percentEncoded: false))
    }

    static func images(for drops: [Drop]) -> [String: UIImage] {
        var images: [String: UIImage] = [:]
        for drop in drops where images[drop.showID] == nil {
            images[drop.showID] = image(showID: drop.showID)
        }
        return images
    }
}
