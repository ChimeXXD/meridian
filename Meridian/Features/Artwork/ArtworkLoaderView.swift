import SwiftUI

/// Loads one piece of artwork and hands it, with its palette, to `content`. `nil` until it arrives
/// (or if it can't be loaded), so screens draw their neutral palette first and never block on the network.
struct ArtworkLoaderView<Content: View>: View {
    let url: URL?
    var maxPixel = 1_200
    @ViewBuilder let content: (ArtworkLoader.Loaded?) -> Content

    /// Tagged with its URL, so a new URL (another show) never shows the previous show's art and palette, while
    /// coming back to the same URL keeps its art on screen instead of flashing the neutral palette.
    @State private var loaded: (url: URL, value: ArtworkLoader.Loaded)?

    /// This URL's art: what this view loaded, else what the phone already decoded, so art seen a moment ago (the
    /// row or poster just tapped) is on the first frame with its palette, with no fade (EA-3).
    private var current: ArtworkLoader.Loaded? {
        if let loaded, loaded.url == url { return loaded.value }
        return url.flatMap { ArtworkLoader.cached($0, maxPixel: maxPixel) }
    }

    var body: some View {
        content(current)
            .task(id: url) {
                guard let url, loaded?.url != url else { return }
                if let hit = ArtworkLoader.cached(url, maxPixel: maxPixel) { loaded = (url, hit); return }
                guard let result = try? await ArtworkLoader.shared.load(url, maxPixel: maxPixel) else { return }
                // A fade even under Reduce Motion: it moves nothing, and a cut would flash bright art onto the night
                // (AD-3; Apple's stand-in for motion is a cross-fade).
                withAnimation(.easeOut(duration: 0.35)) { loaded = (url, result) }
            }
    }
}

/// Artwork filling its frame, cropped, with a base colour behind it while it loads.
struct ArtworkFill: View {
    let image: UIImage?
    let base: Color

    init(image: UIImage?, base: Color) {
        self.image = image
        self.base = base
    }

    init(image: UIImage?, palette: ArtworkPalette) {
        self.init(image: image, base: palette.base.color)
    }

    var body: some View {
        Rectangle()
            .fill(base)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .accessibilityIgnoresInvertColors()  // Smart Invert leaves art alone (audit #23)
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}
