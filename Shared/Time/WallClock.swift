import Foundation

/// Turns a listed date and a wall-clock time in a named zone into a UTC instant.
/// Zones are IANA IDs, so clock changes are handled by the calendar, never by fixed offsets.
enum WallClock {
    static func instant(airdate: String, time: String, zone: String, dayOffset: Int) -> Date? {
        guard let timeZone = TimeZone(identifier: zone),
              let date = parseDate(airdate), let clock = parseTime(time) else { return nil }
        // Shift the calendar day in UTC, which has no clock changes, then place the wall-clock
        // time in the zone directly. Going through local midnight breaks in zones whose clocks
        // change at 00:00 (e.g. America/Santiago), where midnight doesn't exist.
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        guard let day = utc.date(from: DateComponents(year: date.year, month: date.month, day: date.day)),
              let shifted = utc.date(byAdding: .day, value: dayOffset, to: day) else { return nil }
        let target = utc.dateComponents([.year, .month, .day], from: shifted)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: target.year, month: target.month, day: target.day,
                                                  hour: clock.hour, minute: clock.minute))
    }

    /// True only for IANA zone IDs such as "America/New_York". Rejects fixed offsets
    /// like "UTC+1" or abbreviations like "EST", which `TimeZone(identifier:)` would accept.
    static func isValidZone(_ identifier: String) -> Bool {
        TimeZone.knownTimeZoneIdentifiers.contains(identifier)
    }

    /// Parses "yyyy-MM-dd", rejecting impossible dates such as 2026-02-30. Zero padding is optional ("2026-1-5").
    static func parseDate(_ text: String) -> (year: Int, month: Int, day: Int)? {
        guard let parts = numbers(text, separator: "-"), parts.count == 3, (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2])
        guard let date = utc.date(from: components),
              utc.dateComponents([.year, .month, .day], from: date) == components else { return nil }
        return (parts[0], parts[1], parts[2])
    }

    /// Parses "HH:mm" on a 24-hour clock. Zero padding is optional ("9:05").
    static func parseTime(_ text: String) -> (hour: Int, minute: Int)? {
        guard let parts = numbers(text, separator: ":"), parts.count == 2,
              (0..<24).contains(parts[0]), (0..<60).contains(parts[1]) else { return nil }
        return (parts[0], parts[1])
    }

    /// Every part as a number, or nil if any part isn't one, so "2026-xx-11-05" or "21:00:" can't pass by losing a part.
    /// Digits only: `Int` alone reads a sign, which let "-0:30" through as 00:30.
    private static func numbers(_ text: String, separator: Character) -> [Int]? {
        let parts = text.split(separator: separator, omittingEmptySubsequences: false)
        guard parts.allSatisfy({ part in !part.isEmpty && part.allSatisfy { $0.isASCII && $0.isNumber } }) else { return nil }
        return parts.compactMap { Int($0) }
    }
}
