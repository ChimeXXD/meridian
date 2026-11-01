import Foundation
import Testing
@testable import Airstamp

/// D4-2: the widget timeline (SPEC §5, CLAUDE.md rule 5).
@Suite("Widget timeline")
struct TimelineProviderTests {
    static let now = Date(iso: "2026-11-02T12:00:00Z")
    static let hour: TimeInterval = 3_600, minute: TimeInterval = 60

    static func drop(_ id: String, at date: Date, confidence: Confidence = .exact, airdate: String? = nil) -> Drop {
        Drop(id: "tvmaze:\(id):1", showID: id, showName: "Show \(id)", season: 1, number: 1, episodeTitle: nil,
             date: date, airdate: airdate, confidence: confidence,
             source: confidence == .dateOnly ? .dateOnly : .broadcast(network: "HBO"),
             provider: ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: false), previousDate: nil)
    }

    static func timeline(_ drops: [Drop], nextReturn: Drop? = nil, now: Date = now) -> WidgetTimeline {
        WidgetTimeline.make(snapshot: DropSnapshot(generatedAt: now, drops: drops, nextReturn: nextReturn), now: now,
                            formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
    }

    static func gaps(_ timeline: WidgetTimeline) -> [TimeInterval] {
        zip(timeline.entries.dropFirst(), timeline.entries).map { $0.date.timeIntervalSince($1.date) }
    }

    @Test("6 drops 2 minutes apart: entries stay 5 minutes apart, each change shows within 5 minutes, reload at the first")
    func spacingAndPolicy() throws {
        let first = Self.now.addingTimeInterval(26 * Self.hour)
        let drops = (0..<6).map { Self.drop("\($0)", at: first.addingTimeInterval(Double($0) * 2 * Self.minute)) }
        let timeline = Self.timeline(Array(drops.reversed()))

        #expect(Self.gaps(timeline).allSatisfy { $0 >= WidgetTimeline.minimumSpacing })
        #expect(timeline.entries.first?.date == Self.now)
        #expect(timeline.reloadDate == first)
        for drop in drops.prefix(WidgetTimeline.dropsAhead) {
            for change in [drop.date, drop.date.addingTimeInterval(Self.hour)] {
                #expect(timeline.entries.contains { $0.date >= change && $0.date < change + WidgetTimeline.minimumSpacing },
                        "no entry within 5 minutes of \(change)")
            }
        }
        // "Out now" is never shown before its drop, and the first drop's is on time.
        let out = try #require(timeline.entries.first { $0.state == .outNow })
        #expect(out.date == first)
        #expect(out.current?.id == drops[0].id)
    }

    @Test("entries at each drop and an hour after; the hour after moves to the next drop")
    func entriesAtDropAndHourAfter() throws {
        let soon = Self.drop("1", at: Self.now.addingTimeInterval(3 * Self.hour + 17 * Self.minute))
        let later = Self.drop("2", at: Self.now.addingTimeInterval(30 * Self.hour + 41 * Self.minute))
        let timeline = Self.timeline([later, soon])
        let dates = timeline.entries.map(\.date)

        for drop in [soon, later] {
            #expect(dates.contains(drop.date))
            #expect(dates.contains(drop.date.addingTimeInterval(Self.hour)))
        }
        let atDrop = try #require(timeline.entries.first { $0.date == soon.date })
        #expect(atDrop.state == .outNow && atDrop.current?.id == soon.id)
        let hourAfter = try #require(timeline.entries.first { $0.date == soon.date.addingTimeInterval(Self.hour) })
        #expect(hourAfter.state == .countingDown && hourAfter.current?.id == later.id)
        #expect(timeline.reloadDate == soon.date)
        #expect(Self.gaps(timeline).allSatisfy { $0 >= WidgetTimeline.minimumSpacing })
    }

    @Test("static counts refresh hourly, and every 5 minutes in the last hour, up to the horizon")
    func refreshEntries() {
        let drop = Self.drop("1", at: Self.now.addingTimeInterval(40 * Self.hour + 23 * Self.minute))
        let timeline = Self.timeline([drop])
        let before = timeline.entries.filter { $0.date < drop.date }

        #expect(Self.gaps(WidgetTimeline(entries: before)).allSatisfy { $0 <= Self.hour })
        let lastHour = before.filter { $0.date >= drop.date.addingTimeInterval(-Self.hour) }
        #expect(lastHour.count == 12)
        #expect(Self.gaps(WidgetTimeline(entries: lastHour)).allSatisfy { $0 == WidgetTimeline.minimumSpacing })
        #expect(timeline.entries.count < 120)
    }

    @Test("a drop past the horizon reloads at the horizon, so its count never freezes")
    func farDropReloadsAtHorizon() {
        let drop = Self.drop("1", at: Self.now.addingTimeInterval(9 * 24 * Self.hour))
        let timeline = Self.timeline([drop])
        #expect(timeline.reloadDate == Self.now.addingTimeInterval(WidgetTimeline.refreshHorizon))
        let horizon = Self.now.addingTimeInterval(WidgetTimeline.refreshHorizon)
        #expect(timeline.entries.filter { $0.date > Self.now && $0.date <= horizon }.count <= 49)
        // Past the horizon, only the drop's day edges within a week (D-51), so a late reload never freezes "Nd 0:00".
        let edges = (1...7).map { drop.date.addingTimeInterval(-Double($0) * 24 * Self.hour) }
        let beyond = timeline.entries.filter { $0.date > horizon && $0.date < drop.date }
        #expect(!beyond.isEmpty && beyond.allSatisfy { entry in edges.contains(entry.date) })
    }

    @Test("a drop already out stays Out now until its hour ends, then the next one leads")
    func alreadyOut() throws {
        let out = Self.drop("1", at: Self.now.addingTimeInterval(-10 * Self.minute))
        let next = Self.drop("2", at: Self.now.addingTimeInterval(5 * Self.hour))
        let timeline = Self.timeline([out, next])

        #expect(timeline.entries.first?.state == .outNow)
        #expect(timeline.entries.first?.current?.id == out.id)
        let moved = try #require(timeline.entries.first { $0.date == out.date.addingTimeInterval(Self.hour) })
        #expect(moved.current?.id == next.id)
        #expect(timeline.reloadDate == next.date)
    }

    @Test("a date-only drop shows its airdate with no timer until that day ends where you are, then leaves")
    func dateOnly() throws {
        let undated = Self.drop("1", at: Date(iso: "2026-11-11T12:00:00Z"), confidence: .dateOnly, airdate: "2026-11-11")
        let timeline = Self.timeline([undated])

        // Midnight after Wed 11 Nov in Lagos is 23:00Z: the widget mustn't keep a passed day when the app isn't opened.
        let dayEnds = Date(iso: "2026-11-11T23:00:00Z")
        #expect(timeline.entries.map(\.date) == [Self.now, dayEnds])
        #expect(timeline.entries.first?.state == .dateOnly)
        #expect(timeline.entries.last?.state == .nothing)
        // That's 9 days off, so the reload comes at the 48-hour horizon; on the day itself it comes at midnight.
        #expect(timeline.reloadDate == Self.now.addingTimeInterval(WidgetTimeline.refreshHorizon))
        #expect(Self.timeline([undated], now: Date(iso: "2026-11-11T10:00:00Z")).reloadDate == dayEnds)

        // A timed drop leads; the date-only one follows it in the rows, even when its sort key is sooner.
        let timed = Self.drop("2", at: Date(iso: "2026-11-14T02:00:00Z"))
        let mixed = try #require(Self.timeline([undated, timed]).entries.first)
        #expect(mixed.current?.id == timed.id)
        #expect(mixed.upNext.map(\.id) == [timed.id, undated.id])
    }

    @Test("an empty or missing snapshot is one 'nothing' entry with no reload, keeping the next return")
    func emptySnapshot() {
        let back = Self.drop("9", at: Date(iso: "2027-07-09T12:00:00Z"), confidence: .dateOnly, airdate: "2027-07-09")
        for timeline in [Self.timeline([], nextReturn: back), WidgetTimeline.make(snapshot: nil, now: Self.now)] {
            #expect(timeline.entries.count == 1)
            #expect(timeline.entries.first?.state == .nothing)
            #expect(timeline.entries.first?.date == Self.now)
            #expect(timeline.reloadDate == nil)
        }
        #expect(Self.timeline([], nextReturn: back).entries.first?.nextReturn == back)
    }

    @Test("every day edge of each drop in the next 7 days gets an entry, past the 48 h horizon and next to other changes")
    func dayEdges() {
        // Days away, its count reads "Nd" + a timer to the next edge (D-51); a missing entry freezes it at "Nd 0:00".
        let far = Self.drop("far", at: Self.now + 5 * 24 * Self.hour + 2 * Self.minute)
        // A date-only drop whose day ends at Lagos midnight, 2 minutes before one of far's edges.
        let undated = Self.drop("undated", at: Self.now + 24 * Self.hour, confidence: .dateOnly, airdate: "2026-11-02")
        let timeline = Self.timeline([far, undated])
        for days in 1...5 {
            let edge = far.date.addingTimeInterval(-Double(days) * 24 * Self.hour)
            #expect(timeline.entries.contains { $0.date >= edge && $0.date < edge + WidgetTimeline.minimumSpacing },
                    "no entry within 5 minutes of the \(days)-day edge \(edge)")
        }
        #expect(Self.gaps(timeline).allSatisfy { $0 >= WidgetTimeline.minimumSpacing })
    }

    @Test("the rows are the next 4 drops, soonest first (the large widget's hero and 3 rows)")
    func rows() throws {
        let drops = (1...5).map { Self.drop("\($0)", at: Self.now.addingTimeInterval(Double($0) * 7 * Self.hour)) }
        let first = try #require(Self.timeline(drops.shuffled()).entries.first)
        #expect(first.upNext.map(\.id) == drops.prefix(4).map(\.id))
        #expect(first.current?.id == drops[0].id)
    }

    @Test("a next return whose listed day has ended is dropped, never 'returns yesterday'")
    func staleReturn() {
        let back = Self.drop("9", at: Self.now - 48 * Self.hour, confidence: .dateOnly, airdate: "2026-10-01")
        #expect(Self.timeline([], nextReturn: back).entries.first?.nextReturn == nil)
    }

    @Test("followed shows with nothing scheduled reach every entry, in follow order")
    func nothingScheduled() {
        let quiet = [QuietShow(showID: "9", name: "From", status: "Running", lastAired: nil),
                     QuietShow(showID: "anilist:151807", name: "Solo Leveling", status: "FINISHED", lastAired: nil)]
        let snapshot = DropSnapshot(generatedAt: Self.now, drops: [Self.drop("1", at: Self.now + 3 * Self.hour)],
                                    nextReturn: nil, nothingScheduled: quiet)
        let timeline = WidgetTimeline.make(snapshot: snapshot, now: Self.now,
                                           formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
        #expect(timeline.entries.count > 1)
        #expect(timeline.entries.allSatisfy { $0.nothingScheduled == quiet })
    }

    @Test("'+N more this week' counts the drops a widget can't fit that are due within 7 days, date-only ones too")
    func moreThisWeek() throws {
        let timed = (1...6).map { Self.drop("\($0)", at: Self.now.addingTimeInterval(Double($0) * 7 * Self.hour)) }
        let nextWeek = Self.drop("late", at: Self.now.addingTimeInterval(8 * 24 * Self.hour))
        // Date-only drops sort after every timed one, so this one is never in the rows, but it's still this week.
        let tomorrow = Self.drop("undated", at: Self.now.addingTimeInterval(24 * Self.hour), confidence: .dateOnly,
                                 airdate: "2026-11-03")
        let undatedLater = Self.drop("undated-later", at: Self.now.addingTimeInterval(10 * 24 * Self.hour),
                                     confidence: .dateOnly, airdate: "2026-11-12")
        let first = try #require(Self.timeline(timed + [nextWeek, tomorrow, undatedLater]).entries.first)
        #expect(first.moreThisWeek(showing: 3) == 4, "drops 4, 5, 6 and tomorrow's date-only one, not the later ones")
        #expect(first.moreThisWeek(showing: 4) == 3)
        #expect(first.moreThisWeek(showing: 1) == 6)
        #expect(Self.timeline(Array(timed.prefix(3))).entries.first?.moreThisWeek(showing: 3) == 0)
    }
}

private extension WidgetTimeline {
    init(entries: [WidgetMoment]) { self.init(entries: entries, reloadDate: nil) }
}
