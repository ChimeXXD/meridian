import Foundation

/// The widget timeline for a snapshot (SPEC §5, CLAUDE.md rule 5). Pure, so `TimelineProviderTests` can check it
/// without WidgetKit.
///
/// - One entry now, one at each of the next 5 timed drops ("Out now" starts) and one an hour after each ("Out now"
///   ends and the widget moves to the next drop).
/// - Refresh entries keep the static counts honest while the current drop counts down: every hour ("2d 4h", the
///   circular "4h") and every 5 minutes in its last hour (the circular "38m"). They stop at `refreshHorizon`; the
///   reload is due by then. Those that step the still "2d 4h" land `edgeLag` after the hour (see `refreshTimes`).
/// - 24 hours before each drop ahead is a change: the still "1d 0h" turns into the ticking timer there (Chime, 2 Nov:
///   only the last day ticks). Its other day edges within 7 days are changes too, so the rows' days step down and a
///   late reload never leaves the hero a day out.
/// - No two entries are closer than 5 minutes. A change that falls inside that gap moves to 5 minutes after the
///   entry before it (never earlier, so "Out now" is never shown before the drop). A refresh entry within 5 minutes
///   before a drop change is dropped, so drops win; one just after a change moves to 5 minutes after it, so the
///   still count never stays an hour out.
/// - A date-only drop shows its airdate until that day ends in the viewer's zone, then leaves: an entry at that
///   midnight, so a widget never keeps a day that has passed when the app isn't opened.
/// - Reload `.after(nextDrop)`: the next timed drop still ahead (or a date-only day's end), or the refresh horizon if
///   that's sooner. Nil means `.never`: nothing is ahead, and the app reloads timelines when it writes a new snapshot.
struct WidgetTimeline: Hashable, Sendable {
    static let minimumSpacing: TimeInterval = 5 * 60
    static let dropsAhead = 5
    static let rowCount = 4
    static let week: TimeInterval = 7 * 86_400
    static let refreshHorizon: TimeInterval = 48 * 3_600
    static let outNowWindow = CountdownFormatter.outNowWindow
    /// How far past an hour or day edge the entries that step the still count land (see `refreshTimes`).
    static let edgeLag: TimeInterval = 1

    var entries: [WidgetMoment]
    var reloadDate: Date?

    static func make(snapshot: DropSnapshot?, now: Date, formatter: DropFormatter = DropFormatter()) -> WidgetTimeline {
        let drops = snapshot?.drops ?? []
        let showing = live(drops, at: now, formatter: formatter)
        let timed = showing.filter { $0.confidence != .dateOnly }
        let ahead = Array(timed.prefix(dropsAhead))
        let horizon = now.addingTimeInterval(refreshHorizon)
        let dayEnds = showing.compactMap { dayEnd(of: $0, formatter: formatter) }.filter { $0 > now }

        // Each day edge of the drops ahead within a week is a change like a drop, never dropped for a nearby one, and
        // kept past the refresh horizon in case the reload is late. The last day's is exact: 24 hours left already
        // ticks. The others step the still count, so they land a second after the edge, like the hourly refreshes.
        // Spelled out step by step with explicit types: Xcode 26.6 (CI) gave up type-checking it as one expression.
        let weekEnd = now.addingTimeInterval(week)
        var dayEdges: [Date] = []
        for drop in ahead {
            for days in 1...7 {
                let lag: TimeInterval = days > 1 ? edgeLag : 0
                let edge = drop.date.addingTimeInterval(-Double(days) * 86_400 + lag)
                if edge > now && edge <= weekEnd { dayEdges.append(edge) }
            }
        }
        let dropMoments: [Date] = ahead.flatMap { [$0.date, $0.date.addingTimeInterval(outNowWindow)] }
        let changes = Set(dropMoments + dayEnds + dayEdges).filter { $0 > now }
        let anchors = changes.union([now])
        let planned = refreshTimes(ahead, now: now, horizon: horizon)
        let refreshes = planned.compactMap { time -> Date? in
            guard time > now else { return nil }
            // A change just before a refresh still draws the hour that is ending, so dropping the refresh would leave
            // the still count an hour out: it lands 5 minutes after that change instead, unless that crowds the next
            // refresh. A change at or just after it redraws in time, so drops win.
            let at = anchors.filter { $0 < time && time.timeIntervalSince($0) < minimumSpacing }.max()
                .map { $0.addingTimeInterval(minimumSpacing) } ?? time
            let crowded = anchors.contains { $0 >= time && $0 < at.addingTimeInterval(minimumSpacing) }
                || (at > time && planned.contains { $0 > time && $0 < at.addingTimeInterval(minimumSpacing) })
            return crowded ? nil : at
        }
        let dates = spaced([now] + changes.union(refreshes).sorted())
        let entries = dates.map {
            moment(at: $0, drops: drops, nextReturn: snapshot?.nextReturn,
                   nothingScheduled: snapshot?.nothingScheduled ?? [], formatter: formatter)
        }
        let next = ([timed.first { $0.date > now }?.date] + dayEnds.map(Optional.some)).compactMap(\.self).min()
        return WidgetTimeline(entries: entries, reloadDate: next.map { min($0, horizon) })
    }

    /// The moment at `date`: timed drops not yet an hour past, soonest first, then the date-only ones whose day
    /// hasn't ended. A drop is due this week when its time, or a date-only drop's listed day, starts within 7 days.
    static func moment(at date: Date, drops: [Drop], nextReturn: Drop?, nothingScheduled: [QuietShow] = [],
                       formatter: DropFormatter = DropFormatter()) -> WidgetMoment {
        let showing = live(drops, at: date, formatter: formatter)
        let weekEnd = date.addingTimeInterval(week)
        let thisWeek = showing.filter { drop in
            guard drop.confidence == .dateOnly else { return drop.date < weekEnd }
            return dayStart(of: drop, formatter: formatter).map { $0 < weekEnd } ?? false
        }
        // A return whose listed day has ended would read "Silo returns <yesterday>"; it's gone like its drop.
        let back = nextReturn.flatMap { drop in
            (dayEnd(of: drop, formatter: formatter).map { $0 > date } ?? true) ? drop : nil
        }
        return WidgetMoment(date: date, current: showing.first, upNext: Array(showing.prefix(rowCount)),
                            nextReturn: back, thisWeek: thisWeek.map(\.id), nothingScheduled: nothingScheduled)
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

    /// Midnight that starts a date-only drop's airdate where the viewer is (not `dayEnd` minus 24 hours, which is
    /// wrong on a day the clocks change); nil for a timed drop or one with no airdate.
    private static func dayStart(of drop: Drop, formatter: DropFormatter) -> Date? {
        guard drop.confidence == .dateOnly, let airdate = drop.airdate else { return nil }
        return WallClock.instant(airdate: airdate, time: "00:00", zone: formatter.timeZone.identifier, dayOffset: 0)
    }

    /// While each drop is the one counted down to (from when the drop before it leaves until its own time):
    /// a refresh on every whole hour before it, and every 5 minutes in its last hour. More than a day out the count
    /// stands still, rounded down, and drops an hour just after each whole hour: drawn on the hour itself it would
    /// still read the hour that is ending ("2d 4h" for all of 2d 3h…), so those refreshes land `edgeLag` later.
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
                times += (hourly + lastHour).map { before in
                    drop.date.addingTimeInterval(-before + (before > CountdownFormatter.tickingWindow ? edgeLag : 0))
                }.filter { $0 >= start && $0 < end }
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
