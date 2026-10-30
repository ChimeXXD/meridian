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

/// Copy shared by the Night Sky screens.
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

    /// When the episode is out, in words: "Out today at 19:21", "Out Sun at 20:31", "Released today at 19:21",
    /// or "Out Thu 19 Nov" for a date-only drop, whose "Date only" chip says the time isn't announced (D-28).
    /// `naming` adds the place whose clock the time is on ("Out today at 19:21 Lagos time"), so the screen says
    /// once which zone its times are in.
    static func outLine(_ drop: Drop, now: Date, formatter: DropFormatter, naming: Bool = false) -> String {
        if drop.confidence == .dateOnly {
            return "Out \(drop.airdate.flatMap(formatter.airdate) ?? "date to be confirmed")"
        }
        let day = formatter.relativeDay(drop.date, now: now)
        let spoken = ["Today": "today", "Tomorrow": "tomorrow", "Yesterday": "yesterday"][day] ?? day
        let line = "\(drop.date <= now ? "Released" : "Out") \(spoken) at \(formatter.localTime(drop.date))"
        guard naming, let place = formatter.timeZone.identifier.split(separator: "/").last else { return line }
        return "\(line) \(place.replacingOccurrences(of: "_", with: " ")) time"
    }

    /// Show detail's time facts: your time with its zone, against the broadcast time when there is one. The
    /// episode, provider and source are already on the line under the countdown.
    static func timeFacts(_ drop: Drop, now: Date, zone: String?, formatter: DropFormatter) -> [(label: String, value: String)] {
        let yours = drop.confidence == .dateOnly
            ? yourTime(drop, now: now, formatter: formatter)
            : "\(yourTime(drop, now: now, formatter: formatter)) \(formatter.zoneAbbreviation(drop.date))"
        var rows = [("Your time", yours)]
        if let broadcast = broadcast(drop, zone: zone, formatter: formatter) { rows.append(("Broadcast", broadcast)) }
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
