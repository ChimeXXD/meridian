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

    var body: some View {
        content(loaded.flatMap { $0.url == url ? $0.value : nil })
            .task(id: url) {
                guard let url, loaded?.url != url,
                      let result = try? await ArtworkLoader.shared.load(url, maxPixel: maxPixel) else { return }
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
