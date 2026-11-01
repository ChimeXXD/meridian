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
/// - A date-only drop shows its airdate until that day ends in the viewer's zone, then leaves: an entry at that
///   midnight, so a widget never keeps a day that has passed when the app isn't opened.
/// - Reload `.after(nextDrop)`: the next timed drop still ahead (or a date-only day's end), or the refresh horizon if
///   that's sooner. Nil means `.never`: nothing is ahead, and the app reloads timelines when it writes a new snapshot.
struct WidgetTimeline: Hashable, Sendable {
    static let minimumSpacing: TimeInterval = 5 * 60
    static let dropsAhead = 5
    static let rowCount = 3
    static let refreshHorizon: TimeInterval = 48 * 3_600
    static let outNowWindow = CountdownFormatter.outNowWindow

    var entries: [WidgetMoment]
    var reloadDate: Date?

    static func make(snapshot: DropSnapshot?, now: Date, formatter: DropFormatter = DropFormatter()) -> WidgetTimeline {
        let drops = snapshot?.drops ?? []
        let showing = live(drops, at: now, formatter: formatter)
        let timed = showing.filter { $0.confidence != .dateOnly }
        let ahead = Array(timed.prefix(dropsAhead))
        let horizon = now.addingTimeInterval(refreshHorizon)
        let dayEnds = showing.compactMap { dayEnd(of: $0, formatter: formatter) }.filter { $0 > now }

        let changes = Set(ahead.flatMap { [$0.date, $0.date.addingTimeInterval(outNowWindow)] } + dayEnds)
            .filter { $0 > now }
        let anchors = changes.union([now])
        let refreshes = refreshTimes(ahead, now: now, horizon: horizon).filter { time in
            time > now && !anchors.contains { abs($0.timeIntervalSince(time)) < minimumSpacing }
        }
        let dates = spaced([now] + changes.union(refreshes).sorted())
        let entries = dates.map { moment(at: $0, drops: drops, nextReturn: snapshot?.nextReturn, formatter: formatter) }
        let next = ([timed.first { $0.date > now }?.date] + dayEnds.map(Optional.some)).compactMap(\.self).min()
        return WidgetTimeline(entries: entries, reloadDate: next.map { min($0, horizon) })
    }

    /// The moment at `date`: timed drops not yet an hour past, soonest first, then the date-only ones whose day
    /// hasn't ended.
    static func moment(at date: Date, drops: [Drop], nextReturn: Drop?,
                       formatter: DropFormatter = DropFormatter()) -> WidgetMoment {
        let showing = live(drops, at: date, formatter: formatter)
        return WidgetMoment(date: date, current: showing.first, upNext: Array(showing.prefix(rowCount)),
                            nextReturn: nextReturn)
    }

    /// Timed drops whose "Out now" hour hasn't ended at `date`, by time; then date-only drops, by airdate, until the
    /// end of their listed day in `formatter`'s zone (their `date` is only a sort key, D-28).
    private static func live(_ drops: [Drop], at date: Date, formatter: DropFormatter) -> [Drop] {
        let ordered = drops.sorted { ($0.date, $0.id) < ($1.date, $1.id) }
        let timed = ordered.filter { $0.confidence != .dateOnly && $0.date.addingTimeInterval(outNowWindow) > date }
        let undated = ordered.filter { drop in
            drop.confidence == .dateOnly && (dayEnd(of: drop, formatter: formatter).map { $0 > date } ?? true)
        }
        return timed + undated
    }

    /// Midnight after a date-only drop's airdate where the viewer is; nil for a timed drop or one with no airdate.
    private static func dayEnd(of drop: Drop, formatter: DropFormatter) -> Date? {
        guard drop.confidence == .dateOnly, let airdate = drop.airdate else { return nil }
        return WallClock.instant(airdate: airdate, time: "00:00", zone: formatter.timeZone.identifier, dayOffset: 1)
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
