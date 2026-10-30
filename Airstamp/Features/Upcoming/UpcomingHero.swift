import SwiftUI

/// The nearest drop as a full-bleed artwork hero (Chime's picks: Insight Timer, Apple TV, HBO Max): the key art
/// fades into a deep tone of its own colour, with a very large thin serif countdown over the fade.
struct UpcomingHero: View {
    let drop: Drop
    let image: UIImage?
    let palette: ArtworkPalette
    let now: Date
    var formatter = DropFormatter()

    static let height: CGFloat = 600

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArtworkFill(image: image, palette: palette)
                .frame(height: Self.height)
            fade
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("NEXT UP · \(day.uppercased())")
                    .font(.caption.weight(.semibold)).tracking(1.6)
                    .foregroundStyle(.white.opacity(0.75))
                Text(drop.showName)
                    .font(.system(size: 34, weight: .bold))
                    .lineLimit(2)
                    .accessibilityIdentifier("upcoming-hero-title")
                CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                              size: 88, tint: .white, formatter: formatter)
                    .environment(\.numeralStudy, .night)
                    .padding(.vertical, -Tokens.Space.xs)
                Text(meta)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                SourceChip(source: drop.source, confidence: drop.confidence)
                    .padding(.top, Tokens.Space.xxs)
            }
            .padding(.horizontal, Tokens.Space.l)
            .padding(.bottom, Tokens.Space.l)
        }
        .frame(height: Self.height)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("upcoming-hero")
    }

    private var day: String { formatter.relativeDay(drop.date, now: now) }

    /// "S4E1 · Today 03:25 · Apple TV"
    private var meta: String {
        let when = drop.confidence == .dateOnly ? "time not announced" : "\(day) \(formatter.localTime(drop.date))"
        return [drop.episodeLabel, when, drop.provider?.display].compactMap(\.self).joined(separator: " · ")
    }

    /// A scrim at the top for the status bar, and the long fade into the palette at the bottom.
    private var fade: some View {
        let base = palette.base.color
        return ZStack {
            LinearGradient(stops: [
                .init(color: base.opacity(0), location: 0.22),
                .init(color: base.opacity(0.35), location: 0.42),
                .init(color: base.opacity(0.75), location: 0.6),
                .init(color: base.opacity(0.95), location: 0.76),
                .init(color: base, location: 0.88),
            ], startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.22))
        }
        .allowsHitTesting(false)
    }
}
