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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content(loaded.flatMap { $0.url == url ? $0.value : nil })
            .task(id: url) {
                guard let url, loaded?.url != url,
                      let result = try? await ArtworkLoader.shared.load(url, maxPixel: maxPixel) else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) { loaded = (url, result) }
            }
    }
}

/// Keeps the status bar readable when content scrolls under it: the page colour fading to clear.
struct StatusBarScrim: View {
    let color: Color

    var body: some View {
        LinearGradient(colors: [color.opacity(0.9), color.opacity(0)], startPoint: .top, endPoint: .bottom)
            .frame(height: 110)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Artwork filling its frame, cropped, with the palette colour behind it while it loads.
struct ArtworkFill: View {
    let image: UIImage?
    let palette: ArtworkPalette

    var body: some View {
        Rectangle()
            .fill(palette.base.color)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}
