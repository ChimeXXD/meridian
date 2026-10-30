import SwiftUI

/// One upcoming drop as a slab tinted from its own poster (Chime's picks: Fixtured colour blocks, Plex and
/// Paramount+ artwork colour, Peacock posters), with the poster, the when and where, and the countdown.
struct ArtDropRow: View {
    let drop: Drop
    let artwork: ShowArtwork?
    /// 1-based, for test IDs (`drop-row-1`).
    let index: Int
    let now: Date
    var formatter = DropFormatter()

    var body: some View {
        ArtworkLoaderView(url: artwork?.posterThumbnail ?? artwork?.poster, maxPixel: 320) { poster in
            let palette = poster?.palette ?? .neutral
            HStack(alignment: .center, spacing: 14) {
                ArtworkFill(image: poster?.image, palette: palette)
                    .frame(width: 66, height: 98)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 5) {
                    Text(drop.showName)
                        .font(.headline)
                        .lineLimit(2)
                        .accessibilityIdentifier("drop-row-\(index)-title")
                    Text(meta)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .accessibilityIdentifier("drop-row-\(index)-time")
                    if let previous = drop.previousDate {
                        Text("Delayed · was \(previousTime(previous))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(uiColor: Tokens.Ink.delayed))
                    }
                    SourceChip(source: drop.source, confidence: drop.confidence)
                    ProviderLabelView(provider: drop.provider)
                }
                Spacer(minLength: Tokens.Space.xs)
                CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                              size: 30, tint: .white, formatter: formatter)
                    .environment(\.numeralStudy, .night)
                    .fixedSize()
            }
            .padding(12)
            .background(slab(palette), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.08)))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("drop-row-\(index)")
    }

    /// A touch lighter than the palette's base so slabs lift off a page tinted by another show, but never below
    /// the palette's 7:1 for white text (a lifted grey slab fell to 6.4:1, and 72% white text to 4.3:1).
    private func slab(_ palette: ArtworkPalette) -> Color {
        let base = palette.base, white = RGBColor(r: 1, g: 1, b: 1)
        let lifted = RGBColor(hue: base.hue, saturation: base.saturation, brightness: min(base.brightness + 0.05, 0.4))
        return (white.contrast(with: lifted) >= 7.5 ? lifted : base).color
    }

    /// Names the old day too when the delay crossed midnight, as `DropRow` does, so "02:00" isn't read as today's.
    private func previousTime(_ previous: Date) -> String {
        formatter.localDay(previous) == formatter.localDay(drop.date)
            ? formatter.localTime(previous)
            : formatter.weekdayTime(previous)
    }

    private var meta: String {
        let when = drop.confidence == .dateOnly
            ? "time not announced"
            : "\(formatter.relativeDay(drop.date, now: now)) \(formatter.localTime(drop.date))"
        return [drop.episodeLabel, when].compactMap(\.self).joined(separator: " · ")
    }
}
