#if DEBUG
import SwiftUI

/// Night Sky, the direction Chime picked from `docs/design/direction-board` (Glass and Poster Colour were dropped).
/// Launch with `-designPreview A`, adding `detail` for Show detail, `bottom` to open scrolled, and a TVmaze ID
/// (`44778`) to make that show the hero.
enum Direction: String, CaseIterable {
    case nightSky = "A"

    static var launched: Direction? {
        ProcessInfo.processInfo.arguments.lazy.compactMap(Direction.init(rawValue:)).first
    }
}

extension ArtworkPalette {
    /// Night Sky's base: near-black with only a hint of the art's hue, so the art fades into night rather than
    /// into a coloured page. Reds, oranges and yellows turn brown when darkened (Chime: "I don't like the brownish
    /// background"), so warm art gets a neutral charcoal; cool art keeps a faint navy, slate or forest tint.
    var night: RGBColor {
        let warm = base.hue < 75 || base.hue > 320
        return RGBColor(hue: base.hue, saturation: warm ? min(base.saturation, 0.08) : min(base.saturation, 0.32),
                        brightness: warm ? 0.11 : 0.14)
    }
}

/// Night Sky's three text roles on the dark base (unslop: primary, secondary, muted), named so the two greys are
/// never confused: secondary is a row's "Out …" line, muted is meta and labels.
enum NightInk {
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.75)
    static let muted = Color.secondary
}

/// Copy shared by the Night Sky screens. How sure a time is lives in `ReleaseWording` (Shared/Time, tested).
enum DirectionCopy {
    /// "S4E1 · Apple TV"
    static func episodeAndProvider(_ drop: Drop) -> String {
        [drop.episodeLabel, drop.provider?.display].compactMap(\.self).joined(separator: " · ")
    }
}

/// A round Liquid Glass button (Insight Timer's pause button, TIDE's controls).
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

/// Past episodes, newest first.
struct EpisodeRows: View {
    let episodes: [ShowDetailArtView.PastEpisode]
    let ink: Color
    var formatter = DropFormatter()

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(episodes.enumerated()), id: \.element) { index, episode in
                HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s) {
                    Text(episode.label)
                        .font(.footnote.monospacedDigit().weight(.semibold))
                        .foregroundStyle(ink.opacity(0.6))
                        .frame(width: 50, alignment: .leading)
                    Text(episode.title).font(.body.weight(.medium))
                    Spacer()
                    Text(formatter.airdate(episode.airdate) ?? "").font(.footnote).foregroundStyle(ink.opacity(0.6))
                }
                .padding(.vertical, Tokens.Space.s)
                .overlay(alignment: .bottom) {
                    if index < episodes.count - 1 { Rectangle().fill(ink.opacity(0.12)).frame(height: 1) }
                }
                .accessibilityIdentifier("detail-episode-\(index + 1)")
            }
        }
        .foregroundStyle(ink)
    }
}
#endif
