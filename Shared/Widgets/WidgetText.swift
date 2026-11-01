import Foundation

/// The words the widgets show, kept apart from the views so they read the same in every family. Certainty is in the
/// verb, through `ReleaseWording` (D-40); a date-only drop's countdown slot already shows its day, so its line only
/// says the time isn't announced.
enum WidgetText {
    /// "Silo · 2d 4h", "Silo · Out now", "Silo · Wed 11 Nov", or nil while the count ticks (the view adds a timer).
    static func inline(_ moment: WidgetMoment, formatter: DropFormatter) -> String? {
        guard let drop = moment.current else { return emptyHeadline(moment, formatter: formatter) }
        switch CountdownFormatter.state(drop: drop.date, confidence: drop.confidence, now: moment.date) {
        case .dateOnly: return "\(drop.showName) · \(day(drop, now: moment.date, formatter: formatter))"
        case .outNow, .released: return "\(drop.showName) · Out now"
        case .coarse(let parts): return "\(drop.showName) · \(CountdownFormatter.text(parts))"
        case .ticking: return nil
        }
    }

    /// The small and medium widgets' line under the countdown: "Out Wed at 02:00", "Expected Mon at 09:00".
    static func outLine(_ drop: Drop, now: Date, formatter: DropFormatter) -> String {
        drop.confidence == .dateOnly ? "Time not announced" : ReleaseWording.outLine(drop, now: now, formatter: formatter)
    }

    /// The rectangular widget's last line: "Out Wed 02:00 · Apple TV", "Expected Mon 09:00 · Netflix",
    /// "Time not announced · Disney+". The provider keeps its country ("HBO · US", D-20).
    static func meta(_ drop: Drop, now: Date, formatter: DropFormatter) -> String {
        let when = drop.confidence == .dateOnly
            ? "Time not announced"
            : "\(ReleaseWording.verb(drop, past: drop.date <= now)) \(formatter.weekdayTime(drop.date))"
        return [when, drop.provider?.display].compactMap(\.self).joined(separator: " · ")
    }

    /// "S4E1 · Apple TV", or "S3E4 · HBO · US".
    static func episodeAndProvider(_ drop: Drop) -> String {
        [drop.episodeLabel, drop.provider?.display].compactMap(\.self).joined(separator: " · ")
    }

    /// With nothing to count down: "Silo returns Fri 9 Jul 2027" when a date is known, else the follow prompt.
    static func emptyHeadline(_ moment: WidgetMoment, formatter: DropFormatter) -> String {
        guard let back = moment.nextReturn else { return "Follow a show" }
        return "\(back.showName) returns \(day(back, now: moment.date, formatter: formatter))"
    }

    /// The line under `emptyHeadline`.
    static func emptyDetail(_ moment: WidgetMoment) -> String {
        moment.nextReturn == nil ? "Its countdown shows up here." : "Nothing else is scheduled."
    }

    /// A date-only drop's listed day ("Wed 11 Nov", D-28); a timed one's relative day in the viewer's zone.
    static func day(_ drop: Drop, now: Date, formatter: DropFormatter) -> String {
        if drop.confidence == .dateOnly {
            return drop.airdate.flatMap { formatter.airdate($0, now: now) } ?? "date to be confirmed"
        }
        let day = formatter.relativeDay(drop.date, now: now)
        return ["Today": "today", "Tomorrow": "tomorrow"][day] ?? day
    }
}
