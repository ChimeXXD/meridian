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
/// never confused: secondary is a row's "Out …" line, muted is meta, labels and the source word.
enum NightInk {
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.75)
    static let muted = Color.secondary
}

/// Copy shared by the Night Sky screens.
enum DirectionCopy {
    /// "Fri 14:38 New York" in the network's zone; only a broadcast time has one. Zones are named by place
    /// everywhere ("Lagos", "New York"), never "GMT+1" on one line and "EDT" on the next.
    static func broadcast(_ drop: Drop, zone: String?, formatter: DropFormatter) -> String? {
        guard drop.confidence != .dateOnly, case .broadcast = drop.source, let zone else { return nil }
        let local = DropFormatter(zoneIdentifier: zone, locale: formatter.locale)
        return "\(local.weekdayTime(drop.date)) \(place(local))"
    }

    /// The city in a zone's IANA name: "Africa/Lagos" → "Lagos", "America/New_York" → "New York".
    /// A zone with no city ("UTC", "Etc/GMT+1", a fixed offset) falls back to its GMT name, because "Etc/GMT+1" is
    /// really UTC-1 and its last component would read the wrong way round.
    static func place(_ formatter: DropFormatter) -> String {
        let zone = formatter.timeZone
        guard zone.identifier.contains("/"), !zone.identifier.hasPrefix("Etc/") else {
            return zone.localizedName(for: .shortStandard, locale: Locale(identifier: "en_US")) ?? zone.identifier
        }
        return String(zone.identifier.split(separator: "/").last ?? "").replacingOccurrences(of: "_", with: " ")
    }

    /// When the episode is out, in words: "Out today at 19:21", "Out Sun at 20:31", "Released today at 19:21",
    /// or "Out Thu 19 Nov" for a date-only drop (D-28). In style A the verb carries the certainty ("Expected …",
    /// "Airs in Japan …") and a date-only line says the time isn't announced.
    /// `naming` adds the place whose clock the time is on ("Out today at 19:21 Lagos time"), so the screen says
    /// once which zone its times are in.
    static func outLine(_ drop: Drop, now: Date, formatter: DropFormatter, naming: Bool = false,
                        style: TrustStyle = .launched) -> String {
        if drop.confidence == .dateOnly {
            let day = drop.airdate.flatMap(formatter.airdate) ?? "date to be confirmed"
            return style == .inWords ? "Out \(day), time not announced" : "Out \(day)"
        }
        let day = formatter.relativeDay(drop.date, now: now)
        let spoken = ["Today": "today", "Tomorrow": "tomorrow", "Yesterday": "yesterday"][day] ?? day
        let verb = drop.date <= now ? "Released" : style == .inWords ? verb(drop) : "Out"
        let line = "\(verb) \(spoken) at \(formatter.localTime(drop.date))"
        return naming ? "\(line) \(place(formatter)) time" : line
    }

    /// The broadcast time in the network's own city, when there is one and it differs from your clock: the headline
    /// already says your time ("Out today at 21:00 Lagos time"). Feeds Show detail's `why` sentence.
    static func timeFacts(_ drop: Drop, zone: String?, formatter: DropFormatter) -> [(label: String, value: String)] {
        // When the network's clock matches yours, the headline already says it.
        if let zone, TimeZone(identifier: zone)?.secondsFromGMT(for: drop.date)
            == formatter.timeZone.secondsFromGMT(for: drop.date) { return [] }
        return broadcast(drop, zone: zone, formatter: formatter).map { [("Broadcast", $0)] } ?? []
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
