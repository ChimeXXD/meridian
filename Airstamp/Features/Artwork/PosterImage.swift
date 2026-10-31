import SwiftUI

/// A show's poster, loaded at runtime (D-37). Without one, a plain surface with a TV glyph, never a broken image.
struct PosterImage: View {
    let url: URL?
    var cornerRadius: CGFloat = 8

    var body: some View {
        ArtworkLoaderView(url: url, maxPixel: 420) { loaded in
            ArtworkFill(image: loaded?.image, base: .white.opacity(0.08))
                .overlay {
                    if url == nil {
                        Image(systemName: "tv").font(.title3).foregroundStyle(NightInk.muted).accessibilityHidden(true)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
