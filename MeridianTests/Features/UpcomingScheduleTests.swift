import Foundation
import Testing
@testable import Meridian

/// Upcoming redraws its page on every whole minute and at the instant a drop changes section, not every second; only
/// the countdowns tick each second (CLAUDE.md rule 4). So between two of the page's entries its sections must not
/// change, or a drop would sit in the wrong section until the next one.
@Suite("Upcoming schedule")
struct UpcomingScheduleTests {
    typealias Fixture = UpcomingSectionsTests
    static let now = Fixture.now
    static let drops = [
        // "after" comes out while "tonight" is still the hero, so it moves between sections.
        Fixture.drop("soon", in: 90), Fixture.drop("tonight", in: 9 * Fixture.hour + 17),
        Fixture.drop("after", in: 9 * Fixture.hour + 629),
        Fixture.drop("week", in: 3 * Fixture.day + 41), Fixture.drop("later", in: 8 * Fixture.day + 7),
        Fixture.drop("dated", in: 2 * Fixture.day, dateOnly: true, airdate: "2026-11-03"),
    ]

    @Test("a timed drop changes section a week, a day, and no time before its drop, and an hour after it")
    func changes() {
        let drop = Fixture.drop("x", in: 10 * Fixture.day)
        #expect(UpcomingSections.changes(drops: [drop, Fixture.drop("d", in: Fixture.day, dateOnly: true)])
                == [drop.date - 7 * Fixture.day, drop.date - Fixture.day, drop.date, drop.date + Fixture.hour])
    }

    @Test("the next entry is the next whole minute, or a section change before it")
    func nextEntry() {
        let changes = [Self.now + 75, Self.now + 90.5]
        #expect(UpcomingSchedule.next(after: Self.now + 1, changes: changes) == Self.now + 60)
        #expect(UpcomingSchedule.next(after: Self.now + 60, changes: changes) == Self.now + 75)
        #expect(UpcomingSchedule.next(after: Self.now + 75, changes: changes) == Self.now + 90.5)
        #expect(UpcomingSchedule.next(after: Self.now + 90.5, changes: changes) == Self.now + 120)
    }

    @Test("the sections never change between two of the page's entries")
    func sectionsHoldBetweenEntries() {
        let schedule = UpcomingSchedule(changes: UpcomingSections.changes(drops: Self.drops))
        var checked = 0
        for entry in schedule.entries(from: Self.now - Fixture.day, mode: .normal) {
            guard entry < Self.now + 10 * Fixture.day else { break }
            let next = UpcomingSchedule.next(after: entry, changes: schedule.changes)
            let atEntry = UpcomingSections.make(drops: Self.drops, nothingScheduled: [], now: entry)
            #expect(atEntry == UpcomingSections.make(drops: Self.drops, nothingScheduled: [], now: next - 0.001),
                    "sections changed between \(entry) and \(next)")
            checked += 1
        }
        #expect(checked > 10 * 24 * 60)
    }
}
