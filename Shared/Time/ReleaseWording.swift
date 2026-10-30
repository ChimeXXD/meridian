import Foundation

/// How sure a time is, said in words instead of a colour code (D-40). The verb of the out line carries the certainty:
/// "Out" for a published time, "Expected" for an estimate, "Airs in Japan" for an anime's Japanese TV time. Show
/// detail explains the source in one sentence. Zones are named by place ("Lagos", "New York"), never by offset.
enum ReleaseWording {
    /// "Out today at 21:00", "Expected Mon at 09:00", "Airs in Japan tomorrow at 01:24",
    /// "Out Thu 19 Nov, time not announced". After the time only a sure time says "Released"; an estimate keeps
    /// "Expected", so it never claims more than its source. `naming` adds the place whose clock the time is on
    /// ("… Lagos time"), once per screen.
    static func outLine(_ drop: Drop, now: Date, formatter: DropFormatter, naming: Bool = false) -> String {
        if drop.confidence == .dateOnly {
            return "Out \(drop.airdate.flatMap(formatter.airdate) ?? "date to be confirmed"), time not announced"
        }
        let day = formatter.relativeDay(drop.date, now: now)
        let spoken = ["Today": "today", "Tomorrow": "tomorrow", "Yesterday": "yesterday"][day] ?? day
        let line = "\(verb(drop, past: drop.date <= now)) \(spoken) at \(formatter.localTime(drop.date))"
        return naming ? "\(line) \(place(formatter)) time" : line
    }

    /// Show detail's one sentence on where the time came from.
    static func explanation(_ drop: Drop, broadcastZone: String?, formatter: DropFormatter) -> String {
        switch drop.source {
        case .broadcast(let network):
            guard let zone = broadcastZone, drop.confidence != .dateOnly else { return "That's when \(network) airs it." }
            let home = DropFormatter(zoneIdentifier: zone, locale: formatter.locale)
            // On the viewer's own clock the headline already says it.
            guard home.timeZone.secondsFromGMT(for: drop.date) != formatter.timeZone.secondsFromGMT(for: drop.date)
            else { return "That's when \(network) airs it." }
            return "That's when \(network) airs it in its home zone: \(home.weekdayTime(drop.date)) \(place(home)) time."
        case .platformRule(let rule):
            return "\(platform(rule)) doesn't publish release times, so this is when its new episodes usually arrive."
        case .override:
            return drop.confidence == .exact
                ? "This time was checked and confirmed."
                : "This time was reported but isn't confirmed yet."
        case .adjusted(let base, let minutes):
            let direction = minutes < 0 ? "taken off" : "added to"
            return "Your \(abs(minutes))-minute adjustment is \(direction) the \(baseTime(base))."
        case .anilist:
            return "This is when it airs on Japanese TV. Streaming services may add it a little later."
        case .dateOnly:
            return "Only the date is announced. The countdown starts once there's a time."
        }
    }

    /// The city in a zone's IANA name: "Africa/Lagos" → "Lagos", "America/New_York" → "New York". A zone with no city
    /// ("UTC", "Etc/GMT+1") uses its GMT name, because "Etc/GMT+1" is really UTC-1.
    static func place(_ formatter: DropFormatter) -> String {
        let zone = formatter.timeZone
        guard zone.identifier.contains("/"), !zone.identifier.hasPrefix("Etc/") else {
            return zone.localizedName(for: .shortStandard, locale: Locale(identifier: "en_US")) ?? zone.identifier
        }
        return String(zone.identifier.split(separator: "/").last ?? "").replacingOccurrences(of: "_", with: " ")
    }

    private static func verb(_ drop: Drop, past: Bool) -> String {
        if case .anilist = drop.source { return past ? "Aired in Japan" : "Airs in Japan" }
        guard drop.confidence == .exact else { return "Expected" }
        return past ? "Released" : "Out"
    }

    /// "Netflix rule" → "Netflix".
    private static func platform(_ rule: String) -> String {
        rule.hasSuffix(" rule") ? String(rule.dropLast(" rule".count)) : rule
    }

    /// What an offset is applied to, in words: "Japanese TV time", "Netflix's usual time", "listed time".
    private static func baseTime(_ base: String) -> String {
        if base == ReleaseSource.anilist.baseLabel { return "Japanese TV time" }
        if base.hasSuffix(" rule") { return "\(platform(base))'s usual time" }
        return "listed time"
    }
}
