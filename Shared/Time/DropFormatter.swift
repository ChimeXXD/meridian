import Foundation

/// Formats UTC instants in one time zone. The only place times become text (CLAUDE.md rule 1).
struct DropFormatter: Sendable {
    let timeZone: TimeZone
    let locale: Locale
    /// Built once: app screens format every second (their countdowns' pace).
    private let calendar: Calendar

    init(timeZone: TimeZone = .current, locale: Locale = .current) {
        self.timeZone = timeZone
        self.locale = locale
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.calendar = calendar
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

    /// "yyyy-MM-dd" of the calendar day `days` away in this zone. Steps calendar days, so a 23- or 25-hour day at a
    /// clock change neither repeats nor skips a day.
    func localDay(_ date: Date, addingDays days: Int) -> String {
        localDay(calendar.date(byAdding: .day, value: days, to: date) ?? date)
    }

    /// "HH:mm" (24-hour) in this zone.
    func localTime(_ date: Date) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    /// A listed airdate as "Wed 29 Apr". It's a calendar date, not an instant,
    /// so it reads the same in every zone (D-28). Nil if the date can't be read.
    /// With `now`, a date in another year adds it ("Fri 9 Jul 2027"), as `relativeDay` does.
    func airdate(_ airdate: String, now: Date? = nil) -> String? {
        guard let parts = WallClock.parseDate(airdate) else { return nil }
        let utc = Self.utc
        guard let date = utc.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day, hour: 12)) else {
            return nil
        }
        // A format style, not a new DateFormatter: app screens call this every second (their countdowns' pace).
        let text = date.formatted(Date.VerbatimFormatStyle(
            format: "\(weekday: .abbreviated) \(day: .defaultDigits) \(month: .abbreviated)",
            locale: locale, timeZone: .gmt, calendar: utc))
        guard let now, parts.year != calendar.component(.year, from: now) else { return text }
        return "\(text) \(parts.year)"
    }

    /// "Today", "Tomorrow", "Yesterday", a weekday within the week ("Wed"), then "Wed 18 Nov",
    /// with the year when it isn't this year ("Fri 9 Jul 2027").
    /// Days are counted in this formatter's zone, so 00:30 Saturday in Lagos is "Tomorrow" on a Friday evening.
    func relativeDay(_ date: Date, now: Date) -> String {
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

    /// An old time beside its new one: "21:00" the same local day, "Thu 21:00" within the week, and "Fri 23 Oct 21:00"
    /// six or more days away, where the weekday alone could be the new time's own and read as no change.
    func time(_ date: Date, besides other: Date) -> String {
        if localDay(date) == localDay(other) { return localTime(date) }
        guard abs(date.timeIntervalSince(other)) >= 6 * 86_400 else { return weekdayTime(date) }
        let dayMonth = date.formatted(verbatim("\(weekday: .abbreviated) \(day: .defaultDigits) \(month: .abbreviated)"))
        return "\(dayMonth) \(localTime(date))"
    }

    /// "Wed 02:00", for the rectangular widget and rows.
    func weekdayTime(_ date: Date) -> String {
        "\(weekday(date)) \(localTime(date))"
    }

    private func weekday(_ date: Date) -> String {
        date.formatted(verbatim("\(weekday: .abbreviated)"))
    }

    private static let utc: Calendar = {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        return utc
    }()

    private func verbatim(_ format: Date.FormatString) -> Date.VerbatimFormatStyle {
        Date.VerbatimFormatStyle(format: format, locale: locale, timeZone: timeZone, calendar: calendar)
    }
}
