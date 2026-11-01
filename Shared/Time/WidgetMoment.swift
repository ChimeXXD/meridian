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
    /// `current` and up to three after it, in the same order: systemMedium shows the first 3, systemLarge all 4.
    var upNext: [Drop]
    /// The next real date when nothing is scheduled: "Silo returns Fri 9 Jul 2027".
    var nextReturn: Drop?
    /// The IDs of every drop due within 7 days of `date`, so a widget can say how many it couldn't fit.
    var thisWeek: [String] = []

    /// The rows under the hero when a widget shows `shown` drops in all.
    func rows(showing shown: Int) -> [Drop] { Array(upNext.prefix(shown).dropFirst()) }

    /// How many drops due this week aren't among the first `shown` of `upNext`: "+3 more this week".
    func moreThisWeek(showing shown: Int) -> Int {
        let visible = Set(upNext.prefix(shown).map(\.id))
        return thisWeek.filter { !visible.contains($0) }.count
    }

    /// The drop VoiceOver describes: the current one, or the next return when nothing is scheduled.
    var spokenDrop: Drop? { current ?? nextReturn }

    var state: State {
        guard let current else { return .nothing }
        if current.confidence == .dateOnly { return .dateOnly }
        return current.date <= date ? .outNow : .countingDown
    }
}
