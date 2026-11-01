import Foundation

/// The widget timeline for a snapshot (SPEC §5, CLAUDE.md rule 5). Pure, so `TimelineProviderTests` can check it
/// without WidgetKit.
///
/// - One entry now, one at each of the next 5 timed drops ("Out now" starts) and one an hour after each ("Out now"
///   ends and the widget moves to the next drop).
/// - Refresh entries keep the static counts honest while the current drop counts down: every hour ("2d 4h", the
///   circular "4h") and every 5 minutes in its last hour (the circular "38m"). Ticking timers need none. They stop at
///   `refreshHorizon`; the reload is due by then.
/// - No two entries are closer than 5 minutes. A change that falls inside that gap moves to 5 minutes after the
///   entry before it (never earlier, so "Out now" is never shown before the drop), and a refresh entry within 5
///   minutes of a drop change is dropped, so drops win.
/// - Reload `.after(nextDrop)`: the next timed drop still ahead, or the refresh horizon if that's sooner. Nil means
///   `.never`: nothing timed is ahead, and the app reloads timelines when it writes a new snapshot.
struct WidgetTimeline: Hashable, Sendable {
    static let minimumSpacing: TimeInterval = 5 * 60
    static let dropsAhead = 5
    static let rowCount = 3
    static let refreshHorizon: TimeInterval = 48 * 3_600
    static let outNowWindow = CountdownFormatter.outNowWindow

    var entries: [WidgetMoment]
    var reloadDate: Date?

    static func make(snapshot: DropSnapshot?, now: Date) -> WidgetTimeline {
        let drops = snapshot?.drops ?? []
        let timed = live(drops, at: now).filter { $0.confidence != .dateOnly }
        let ahead = Array(timed.prefix(dropsAhead))
        let horizon = now.addingTimeInterval(refreshHorizon)

        let changes = Set(ahead.flatMap { [$0.date, $0.date.addingTimeInterval(outNowWindow)] }).filter { $0 > now }
        let anchors = changes.union([now])
        let refreshes = refreshTimes(ahead, now: now, horizon: horizon).filter { time in
            time > now && !anchors.contains { abs($0.timeIntervalSince(time)) < minimumSpacing }
        }
        let dates = spaced([now] + changes.union(refreshes).sorted())
        let entries = dates.map { moment(at: $0, drops: drops, nextReturn: snapshot?.nextReturn) }
        let reload = timed.first { $0.date > now }.map { min($0.date, horizon) }
        return WidgetTimeline(entries: entries, reloadDate: reload)
    }

    /// The moment at `date`: timed drops not yet an hour past, soonest first, then the date-only ones.
    static func moment(at date: Date, drops: [Drop], nextReturn: Drop?) -> WidgetMoment {
        let showing = live(drops, at: date)
        return WidgetMoment(date: date, current: showing.first, upNext: Array(showing.prefix(rowCount)),
                            nextReturn: nextReturn)
    }

    /// Timed drops whose "Out now" hour hasn't ended at `date`, by time; then every date-only drop by airdate.
    /// A date-only drop's `date` is only a sort key (D-28), so it never expires here; the next snapshot drops it.
    private static func live(_ drops: [Drop], at date: Date) -> [Drop] {
        let ordered = drops.sorted { ($0.date, $0.id) < ($1.date, $1.id) }
        let timed = ordered.filter { $0.confidence != .dateOnly && $0.date.addingTimeInterval(outNowWindow) > date }
        return timed + ordered.filter { $0.confidence == .dateOnly }
    }

    /// While each drop is the one counted down to (from when the drop before it leaves until its own time):
    /// a refresh on every whole hour before it, and every 5 minutes in its last hour.
    private static func refreshTimes(_ ahead: [Drop], now: Date, horizon: Date) -> [Date] {
        var times: [Date] = []
        var start = now
        for drop in ahead {
            let end = min(drop.date, horizon)
            if start < end {
                // Whole hours before the drop that fall between `start` and `end`.
                let nearest = max(1, Int((drop.date.timeIntervalSince(end) / 3_600).rounded(.up)))
                let farthest = Int(drop.date.timeIntervalSince(start) / 3_600)
                let hourly = nearest <= farthest ? (nearest...farthest).map { Double($0) * 3_600 } : []
                let lastHour = (1..<12).map { Double($0) * minimumSpacing }
                times += (hourly + lastHour).map { drop.date.addingTimeInterval(-$0) }.filter { $0 >= start && $0 < end }
            }
            start = max(start, drop.date.addingTimeInterval(outNowWindow))
        }
        return times
    }

    /// Sorted dates with none closer than `minimumSpacing`: a date inside the gap moves to the end of it, and dates the
    /// moved one already covers merge into it. Each entry shows the state at its own date, so nothing is lost.
    private static func spaced(_ sorted: [Date]) -> [Date] {
        var kept: [Date] = []
        for date in sorted {
            guard let last = kept.last else { kept.append(date); continue }
            if date <= last { continue }
            kept.append(max(date, last.addingTimeInterval(minimumSpacing)))
        }
        return kept
    }
}
