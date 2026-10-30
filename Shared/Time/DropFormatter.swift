import Foundation

/// Formats UTC instants in one time zone. The only place times become text (CLAUDE.md rule 1).
struct DropFormatter: Sendable {
    let timeZone: TimeZone
    let locale: Locale

    init(timeZone: TimeZone = .current, locale: Locale = .current) {
        self.timeZone = timeZone
        self.locale = locale
    }

    /// A formatter for a named IANA zone, falling back to the device zone if the name is unknown.
    /// Keeps `TimeZone(` lookups inside `Shared/Time` (SPEC formatting criterion).
    init(zoneIdentifier: String, locale: Locale = .current) {
        self.init(timeZone: TimeZone(identifier: zoneIdentifier) ?? .current, locale: locale)
    }

    /// "yyyy-MM-dd" in this zone.
    func localDay(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// "HH:mm" (24-hour) in this zone.
    func localTime(_ date: Date) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    /// A listed airdate as "Wed 29 Apr". It's a calendar date, not an instant,
    /// so it reads the same in every zone (D-28). Nil if the date can't be read.
    func airdate(_ airdate: String) -> String? {
        guard let parts = WallClock.parseDate(airdate) else { return nil }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        guard let date = utc.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day, hour: 12)) else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = .gmt
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date)
    }

    /// "Today", "Tomorrow", "Yesterday", a weekday within the week ("Wed"), then "Wed 18 Nov",
    /// with the year when it isn't this year ("Fri 9 Jul 2027").
    /// Days are counted in this formatter's zone, so 00:30 Saturday in Lagos is "Tomorrow" on a Friday evening.
    func relativeDay(_ date: Date, now: Date) -> String {
        let calendar = calendar
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        case 2...6: return weekday(date)
        default:
            let dayMonth = date.formatted(verbatim("\(weekday: .abbreviated) \(day: .defaultDigits) \(month: .abbreviated)"))
            let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
            return sameYear ? dayMonth : "\(dayMonth) \(calendar.component(.year, from: date))"
        }
    }

    /// The zone's short name at that moment, in US English so New York reads "EDT"/"EST" rather than "GMT-4".
    func zoneAbbreviation(_ date: Date) -> String {
        let style: NSTimeZone.NameStyle = timeZone.isDaylightSavingTime(for: date) ? .shortDaylightSaving : .shortStandard
        return timeZone.localizedName(for: style, locale: Locale(identifier: "en_US")) ?? timeZone.identifier
    }

    /// "Wed 02:00", for the rectangular widget and rows.
    func weekdayTime(_ date: Date) -> String {
        "\(weekday(date)) \(localTime(date))"
    }

    private func weekday(_ date: Date) -> String {
        date.formatted(verbatim("\(weekday: .abbreviated)"))
    }

    private func verbatim(_ format: Date.FormatString) -> Date.VerbatimFormatStyle {
        Date.VerbatimFormatStyle(format: format, locale: locale, timeZone: timeZone, calendar: calendar)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
