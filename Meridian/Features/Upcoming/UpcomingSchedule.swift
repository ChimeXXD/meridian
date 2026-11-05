import SwiftUI

/// Upcoming's page pace: every whole minute (its words, such as "today" and "Updated 14:05", change on a minute) and at
/// the instant any drop changes section, so a drop moves to Out now right at its time. Only the countdowns redraw every
/// second (`.countdown`, CLAUDE.md rule 4), each in its own `TimelineView`, so the page's sort, art and palette don't.
struct UpcomingSchedule: TimelineSchedule {
    /// The instants a drop changes section, sorted (`UpcomingSections.changes`).
    let changes: [Date]

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> UnfoldFirstSequence<Date> {
        sequence(first: startDate) { [changes] date in Self.next(after: date, changes: changes) }
    }

    /// The next whole minute after `date`, or the first section change before it.
    static func next(after date: Date, changes: [Date]) -> Date {
        let minute = Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60 + 60)
        guard let change = changes.first(where: { $0 > date }) else { return minute }
        return min(change, minute)
    }
}
