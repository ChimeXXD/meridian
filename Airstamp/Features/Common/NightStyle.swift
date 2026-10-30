import SwiftUI

/// Night Sky (D-38, D-39, D-40): the show's art fades into a near-black base, a light serif countdown, three greys
/// for text, and no colour outside the artwork.
extension ArtworkPalette {
    /// The base under the art: near-black with only a hint of its hue. Reds, oranges and yellows turn brown when
    /// darkened (Chime: "I don't like the brownish background"), so warm art gets a neutral charcoal; cool art keeps a
    /// faint navy, slate or forest tint.
    var night: RGBColor {
        let warm = base.hue < 75 || base.hue > 320
        return RGBColor(hue: base.hue, saturation: warm ? min(base.saturation, 0.08) : min(base.saturation, 0.32),
                        brightness: warm ? 0.11 : 0.14)
    }
}

/// Night Sky's three text roles on the dark base: secondary is a row's "Out …" line, muted is meta and labels.
enum NightInk {
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.75)
    static let muted = Color.secondary
}

extension Drop {
    /// "S4E1 · Apple TV", or "S3E4 · HBO · US".
    var episodeAndProvider: String {
        [episodeLabel, provider?.display].compactMap(\.self).joined(separator: " · ")
    }
}

/// A round Liquid Glass button, the only control that sits on the art (the back button).
struct GlassCircleButton: View {
    let systemImage: String
    let label: String
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }
}

/// The key art at the top of Upcoming and Show detail, fading into the night base.
struct NightArtHeader: View {
    let image: UIImage?
    let base: Color
    var height: CGFloat = 472

    var body: some View {
        ZStack {
            ArtworkFill(image: image, palette: .neutral).frame(height: height)
            LinearGradient(stops: [.init(color: base.opacity(0), location: 0.4), .init(color: base, location: 1)],
                           startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.25))
        }
        .frame(height: height)
    }
}
