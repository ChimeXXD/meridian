#if DEBUG
import SwiftUI

/// The three directions on `docs/design/direction-board`, built as real screens for Chime to choose from.
/// Launch with `-designPreview A` (or `B`, `C`), adding `detail` for Show detail and `bottom` to open scrolled.
/// Debug only: the two directions that lose are deleted.
enum Direction: String, CaseIterable {
    case nightSky = "A", glass = "B", posterColour = "C"

    static var launched: Direction? {
        ProcessInfo.processInfo.arguments.lazy.compactMap(Direction.init(rawValue:)).first
    }
}

extension ArtworkPalette {
    /// Night Sky: Insight Timer's quiet base, a dark, low-saturation tone of the art's hue (olive, slate, plum).
    var muted: RGBColor { RGBColor(hue: base.hue, saturation: min(base.saturation, 0.28), brightness: 0.19) }

    /// Poster Colour: a bold tone of the art's hue for whole cards and pages (Paramount+, Fixtured). Greys stay grey.
    var vivid: RGBColor {
        guard base.saturation > 0.08 else { return RGBColor(hue: 0, saturation: 0, brightness: 0.3) }
        // Bright enough that warm posters read as orange or mustard rather than brown; `ink` picks the text colour.
        return RGBColor(hue: base.hue, saturation: max(base.saturation, 0.68), brightness: 0.76)
    }
}

extension RGBColor {
    /// White text when it reaches 4.5:1 on this colour, otherwise near-black.
    var prefersWhiteText: Bool { RGBColor(r: 1, g: 1, b: 1).contrast(with: self) >= 4.5 }
    var ink: Color { prefersWhiteText ? .white : Color(white: 0.08) }
}

/// Copy the three directions share, so they differ only in look.
enum DirectionCopy {
    /// "Today 21:00", or "Time not announced" for a date-only drop (D-28).
    static func yourTime(_ drop: Drop, now: Date, formatter: DropFormatter) -> String {
        drop.confidence == .dateOnly
            ? "Time not announced"
            : "\(formatter.relativeDay(drop.date, now: now)) \(formatter.localTime(drop.date))"
    }

    /// "Thu 21:00 EDT" in the network's zone; only a broadcast time has one.
    static func broadcast(_ drop: Drop, zone: String?, formatter: DropFormatter) -> String? {
        guard drop.confidence != .dateOnly, case .broadcast = drop.source, let zone else { return nil }
        let local = DropFormatter(zoneIdentifier: zone, locale: formatter.locale)
        return "\(local.weekdayTime(drop.date)) \(local.zoneAbbreviation(drop.date))"
    }

    /// Show detail's fact rows: your time, the broadcast time when there is one, and where to watch.
    static func facts(_ drop: Drop, now: Date, zone: String?, formatter: DropFormatter) -> [(label: String, value: String)] {
        var rows = [("Your time", yourTime(drop, now: now, formatter: formatter))]
        if let broadcast = broadcast(drop, zone: zone, formatter: formatter) { rows.append(("Broadcast", broadcast)) }
        rows.append(("Where to watch", drop.provider?.display ?? "Not listed"))
        return rows
    }

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

/// Label and value rows with hairlines, coloured by the page's ink.
struct FactRows: View {
    let rows: [(label: String, value: String)]
    let ink: Color
    var serif = false

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(alignment: .firstTextBaseline) {
                    Text(row.label).foregroundStyle(ink.opacity(0.7))
                    Spacer(minLength: Tokens.Space.s)
                    Text(row.value)
                        .font(serif ? .system(.body, design: .serif) : .body.weight(.semibold))
                        .multilineTextAlignment(.trailing)
                }
                .font(.subheadline)
                .padding(.vertical, Tokens.Space.s)
                .overlay(alignment: .bottom) {
                    if index < rows.count - 1 { Rectangle().fill(ink.opacity(0.12)).frame(height: 1) }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("detail-fact-\(index + 1)")
            }
        }
        .foregroundStyle(ink)
    }
}

/// Past episodes, newest first.
struct EpisodeRows: View {
    let episodes: [ShowDetailArtView.PastEpisode]
    let ink: Color
    var serif = false
    var formatter = DropFormatter()

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(episodes.enumerated()), id: \.element) { index, episode in
                HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s) {
                    Text(episode.label)
                        .font(.footnote.monospacedDigit().weight(.semibold))
                        .foregroundStyle(ink.opacity(0.6))
                        .frame(width: 50, alignment: .leading)
                    Text(episode.title).font(serif ? .system(size: 18, design: .serif) : .body.weight(.medium))
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
