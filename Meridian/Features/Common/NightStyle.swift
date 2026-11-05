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

    /// The same line as VoiceOver should say it: "Season 4, episode 1, HBO US", not "S 4 E 1" (UX audit #32).
    var spokenEpisodeAndProvider: String {
        let episode = number.map { n in season.map { "Season \($0), episode \(n)" } ?? "Episode \(n)" }
        let service = provider?.display.replacingOccurrences(of: " · ", with: " ")
        return [episode, service].compactMap(\.self).joined(separator: ", ")
    }
}

extension View {
    /// Settings, Credits and Debug on the night base the other tabs use, not the system's pure black (EA-4). Each
    /// section takes `nightRow()`.
    func nightList() -> some View {
        scrollContentBackground(.hidden).background(ArtworkPalette.neutral.night.color)
    }

    /// A grouped list row on the night base: white at 0.08, the same lift as Show detail's action card.
    func nightRow() -> some View {
        listRowBackground(Color.white.opacity(0.08))
    }
}

/// The key art at the top of Upcoming and Show detail, fading into the night base.
struct NightArtHeader: View {
    let image: UIImage?
    let base: Color
    var height: CGFloat = Self.defaultHeight

    /// Upcoming's header; the show pages use 500.
    static let defaultHeight: CGFloat = 472

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// More than half the screen at the default size; 280 at the accessibility sizes, so the facts under it stay on
    /// the first screen (UX audit #25).
    static func shownHeight(_ height: CGFloat, dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? min(height, 280) : height
    }

    private var shown: CGFloat { Self.shownHeight(height, dynamicTypeSize: dynamicTypeSize) }

    var body: some View {
        ZStack {
            // While the art downloads the header is the night base itself, never a grey block (Chime saw one).
            ArtworkFill(image: image, base: base).frame(height: shown)
            LinearGradient(stops: [.init(color: base.opacity(0), location: 0.4), .init(color: base, location: 1)],
                           startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.25))
        }
        .frame(height: shown)
    }
}
