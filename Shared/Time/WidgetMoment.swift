import Foundation

/// What every widget family shows at one moment of its timeline (SPEC §5): the drop it counts down to, and the next few
/// for systemMedium's rows. Built by `WidgetTimeline`; the widget extension makes it its `TimelineEntry`.
struct WidgetMoment: Hashable, Sendable {
    enum State: Hashable, Sendable {
        case countingDown, outNow, dateOnly, nothing
    }

    /// When WidgetKit shows this entry. Views format and count down from it, never from `Date.now`.
    var date: Date
    /// The drop the widget is about: the soonest timed drop not yet an hour past, else the soonest date-only one.
    var current: Drop?
    /// `current` and up to two after it, in the same order (systemMedium).
    var upNext: [Drop]
    /// The next real date when nothing is scheduled: "Silo returns Fri 9 Jul 2027".
    var nextReturn: Drop?

    var state: State {
        guard let current else { return .nothing }
        if current.confidence == .dateOnly { return .dateOnly }
        return current.date <= date ? .outNow : .countingDown
    }
}
