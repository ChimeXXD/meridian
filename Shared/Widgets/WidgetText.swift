import Foundation
import UIKit

/// The words the widgets show, kept apart from the views so they read the same in every family. Certainty is in the
/// verb, through `ReleaseWording` (D-40); a date-only drop's countdown slot already shows its day, so its line only
/// says the time isn't announced.
enum WidgetText {
    /// "Silo · 2d 4h", "Silo · Out now", "Silo · Wed 11 Nov", or nil in the last day (the view adds the live timer).
    /// A name too long for the line shortens ("Frieren: Beyond Jour… · 3d 6h"); what comes after it always stays.
    static func inline(_ moment: WidgetMoment, formatter: DropFormatter) -> String? {
        guard let drop = moment.current else {
            guard let back = moment.nextReturn else { return emptyHeadline(moment, formatter: formatter) }
            return shortened(back.showName, before: " returns \(day(back, now: moment.date, formatter: formatter))")
        }
        return switch CountdownFormatter.state(drop: drop.date, confidence: drop.confidence, now: moment.date) {
        case .dateOnly: shortened(drop.showName, before: " · \(day(drop, now: moment.date, formatter: formatter))")
        case .outNow, .released: shortened(drop.showName, before: " · Out now")
        case .coarse(let parts): shortened(drop.showName, before: " · \(CountdownFormatter.text(parts))")
        case .ticking: nil  // the view adds the timer
        }
    }

    /// The inline line's room: the narrowest Lock Screen's 234 pt, measured in the 17 pt system font the renders draw
    /// it in (break-ui BU-1: a long name pushed the count, "Out now" or the day off the end). The system draws the
    /// line in its own font, so the phone has the last word.
    static let inlineWidth: CGFloat = 234

    /// The width of an inline line in that font.
    static func inlineTextWidth(_ line: String) -> CGFloat {
        (line as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 17)]).width
    }

    /// The show's name as the inline line can fit it in front of `suffix`: whole when it fits, else cut with "…",
    /// keeping at least its first character.
    static func inlineName(_ name: String, before suffix: String) -> String {
        guard inlineTextWidth(name + suffix) > inlineWidth else { return name }
        var kept = Substring(name)
        while kept.count > 1, inlineTextWidth(String(kept) + "…" + suffix) > inlineWidth { kept.removeLast() }
        while kept.count > 1, let last = kept.last, last.isWhitespace || last.isPunctuation { kept.removeLast() }
        return String(kept) + "…"
    }

    private static func shortened(_ name: String, before suffix: String) -> String {
        inlineName(name, before: suffix) + suffix
    }

    /// The small and medium widgets' line under the countdown: "Out Wed at 02:00", "Expected Mon at 09:00".
    static func outLine(_ drop: Drop, now: Date, formatter: DropFormatter) -> String {
        drop.confidence == .dateOnly ? "Time not announced" : ReleaseWording.outLine(drop, now: now, formatter: formatter)
    }

    /// When it's out, led by how sure that is (#Udemy puts it on the rectangular widget's top line): "Out today 22:10",
    /// "Expected tomorrow 09:00", "Out Wed 02:00" within the week, "Out Wed 11 Nov 02:00" from 7 days (a weekday alone
    /// named the wrong week, break-ui BU-2), "Released today 18:40", "Time not announced". The relative day is the
    /// out line's (`DropFormatter.relativeDay`); the hourly entries redraw it past midnight.
    static func when(_ drop: Drop, now: Date, formatter: DropFormatter) -> String {
        guard drop.confidence != .dateOnly else { return "Time not announced" }
        let day = formatter.relativeDay(drop.date, now: now)
        let spoken = ["Today": "today", "Tomorrow": "tomorrow", "Yesterday": "yesterday"][day] ?? day
        return "\(ReleaseWording.verb(drop, past: drop.date <= now)) \(spoken) \(formatter.localTime(drop.date))"
    }

    /// The tag for shows a widget can't fit: "+3 more this week"; nil when everything fits.
    static func more(_ count: Int) -> String? {
        count > 0 ? "+\(count) more this week" : nil
    }

    /// "S4E1 · Apple TV", or "S3E4 · HBO · US".
    static func episodeAndProvider(_ drop: Drop) -> String {
        [drop.episodeLabel, drop.provider?.display].compactMap(\.self).joined(separator: " · ")
    }

    /// With nothing to count down: "Silo returns Fri 9 Jul 2027" when a date is known; "Nothing scheduled" when shows
    /// are followed but none has a next episode; else the follow prompt.
    static func emptyHeadline(_ moment: WidgetMoment, formatter: DropFormatter) -> String {
        guard let back = moment.nextReturn else {
            return moment.nothingScheduled.isEmpty ? "Follow a show" : nothingScheduled
        }
        return "\(back.showName) returns \(day(back, now: moment.date, formatter: formatter))"
    }

    /// The line under `emptyHeadline`. The app never promises when it next checks (D-27).
    static func emptyDetail(_ moment: WidgetMoment) -> String {
        if moment.nextReturn != nil { return "Nothing else is scheduled." }
        return moment.nothingScheduled.isEmpty
            ? "Its countdown shows up here." : "Meridian checks again each time you open it."
    }

    /// What a followed show with no next episode says in a widget row, where a countdown would be.
    static let nothingScheduled = "Nothing scheduled"

    /// A date-only drop's listed day ("Wed 11 Nov", D-28); a timed one's relative day in the viewer's zone.
    static func day(_ drop: Drop, now: Date, formatter: DropFormatter) -> String {
        if drop.confidence == .dateOnly {
            return drop.airdate.flatMap { formatter.airdate($0, now: now) } ?? "date to be confirmed"
        }
        let day = formatter.relativeDay(drop.date, now: now)
        return ["Today": "today", "Tomorrow": "tomorrow"][day] ?? day
    }
}
