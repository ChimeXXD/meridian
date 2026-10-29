import Foundation

/// Formats UTC instants in one time zone. The only place times become text (CLAUDE.md rule 1).
struct DropFormatter: Sendable {
    let timeZone: TimeZone
    let locale: Locale

    init(timeZone: TimeZone = .current, locale: Locale = .current) {
        self.timeZone = timeZone
        self.locale = locale
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

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
