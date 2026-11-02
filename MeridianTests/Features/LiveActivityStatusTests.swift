import Foundation
import Testing
@testable import Meridian

/// UX audit #11: Show detail's Live Activity switch said "Starts 2 hours before" even when nothing would be booked.
/// Its subtitle now says what will really happen, in this order of priority.
@Suite("Live Activity status")
struct LiveActivityStatusTests {
    static let now = Date(iso: "2026-11-02T18:00:00Z")
    static let day: TimeInterval = 86_400

    static func drop(in seconds: TimeInterval = 3 * 3_600, confidence: Confidence = .exact) -> Drop {
        Drop(id: "tvmaze:94:1", showID: "94", showName: "Show", season: 1, number: 1, episodeTitle: nil,
             date: now + seconds, airdate: confidence == .dateOnly ? "2026-11-05" : nil, confidence: confidence,
             source: confidence == .dateOnly ? .dateOnly : .broadcast(network: "HBO"), provider: nil, previousDate: nil)
    }

    static func line(isOn: Bool = true, systemEnabled: Bool = true, drop: Drop = drop(), waiting: Bool = false)
        -> LiveActivityStatus.Line {
        LiveActivityStatus.line(isOn: isOn, systemEnabled: systemEnabled, drop: drop, waiting: waiting, now: now)
    }

    @Test("booked as usual: starts the lead before")
    func starts() {
        #expect(Self.line() == .starts)
        #expect(LiveActivityStatus.text(.starts, leadMinutes: 120) == "Starts 2 hours before, on your Lock Screen")
    }

    @Test("off in iOS Settings comes first, then off for this show")
    func off() {
        #expect(Self.line(isOn: false, systemEnabled: false) == .systemOff)
        #expect(Self.line(isOn: false) == .off)
        #expect(LiveActivityStatus.text(.systemOff, leadMinutes: 120) == "Live Activities are off in Settings")
        #expect(LiveActivityStatus.text(.off, leadMinutes: 120) == "Off for this show")
    }

    @Test("nothing to book yet: no time announced, more than a week away, or 3 sooner ones already booked")
    func notYet() {
        #expect(Self.line(drop: Self.drop(confidence: .dateOnly)) == .noTime)
        #expect(Self.line(drop: Self.drop(in: 8 * Self.day)) == .notThisWeek)
        #expect(Self.line(waiting: true) == .waiting)
        #expect(LiveActivityStatus.text(.noTime, leadMinutes: 120) == "Starts once a time is announced")
        #expect(LiveActivityStatus.text(.notThisWeek, leadMinutes: 120) == "Booked once it's within a week")
        #expect(LiveActivityStatus.text(.waiting, leadMinutes: 120) == "Waiting: 3 sooner ones are booked")
    }

    @Test("the week is the planner's: exactly 7 days still books")
    func weekEdge() {
        #expect(Self.line(drop: Self.drop(in: ActivityPlanner.horizon)) == .starts)
        #expect(Self.line(drop: Self.drop(in: ActivityPlanner.horizon + 1)) == .notThisWeek)
    }
}
