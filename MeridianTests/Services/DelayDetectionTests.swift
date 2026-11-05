import Foundation
import Testing
@testable import Meridian

/// SPEC core flow 5 and the D6-1 criteria: a refresh that finds a later time for the same episode keeps the first
/// listed time as `previousDate`, so the views say "Delayed from 21:00" and the Live Activity moves (D-58). Only a
/// sure time can be delayed: a refined estimate isn't the show moving. Monday 2 Nov 2026, 20:00 UTC.
@Suite("Delay detection")
struct DelayDetectionTests {
    static let listed = Date(iso: "2026-11-02T20:00:00Z")
    static let hour: TimeInterval = 3_600

    static func drop(_ episode: Int = 4, at date: Date = listed, confidence: Confidence = .exact,
                     previousDate: Date? = nil) -> Drop {
        Drop(id: "tvmaze:94:\(episode)", showID: "94", showName: "House of the Dragon", season: 3, number: episode,
             episodeTitle: nil, date: date, airdate: confidence == .dateOnly ? "2026-11-02" : nil,
             confidence: confidence,
             source: confidence == .exact ? .broadcast(network: "HBO") : confidence == .dateOnly
                 ? .dateOnly : .platformRule("HBO Max rule"),
             provider: nil, previousDate: previousDate)
    }

    static func carried(_ previous: [Drop], _ fresh: Drop) -> Date? {
        DelayDetection.carry(from: previous, into: [fresh]).first?.previousDate
    }

    @Test("delay detection: a later published time keeps the first listed one, through more delays and refreshes")
    func delayDetection() {
        // Moved an hour later: the old time is kept.
        #expect(Self.carried([Self.drop()], Self.drop(at: Self.listed + Self.hour)) == Self.listed)
        // Moved again: still the first listed time, not the one in between.
        let delayed = Self.drop(at: Self.listed + Self.hour, previousDate: Self.listed)
        #expect(Self.carried([delayed], Self.drop(at: Self.listed + 2 * Self.hour)) == Self.listed)
        // Refreshed with no change: the delay stays on show.
        #expect(Self.carried([delayed], Self.drop(at: Self.listed + Self.hour)) == Self.listed)
    }

    @Test("not a delay: back to the listed time or earlier, the same time, a new episode or a first sight")
    func notDelayed() {
        let delayed = Self.drop(at: Self.listed + Self.hour, previousDate: Self.listed)
        #expect(Self.carried([delayed], Self.drop(at: Self.listed)) == nil)
        #expect(Self.carried([Self.drop()], Self.drop(at: Self.listed - Self.hour)) == nil)
        #expect(Self.carried([Self.drop()], Self.drop()) == nil)
        #expect(Self.carried([Self.drop(4)], Self.drop(5, at: Self.listed + Self.hour)) == nil)
        #expect(Self.carried([], Self.drop(at: Self.listed + Self.hour)) == nil)
    }

    @Test("only a sure time is delayed: an estimate refined, or a time that turns into an estimate, says nothing")
    func onlyExactTimes() {
        let later = Self.listed + Self.hour
        #expect(Self.carried([Self.drop(confidence: .estimated)], Self.drop(at: later)) == nil)
        #expect(Self.carried([Self.drop(confidence: .estimated)], Self.drop(at: later, confidence: .estimated)) == nil)
        #expect(Self.carried([Self.drop()], Self.drop(at: later, confidence: .estimated)) == nil)
        #expect(Self.carried([Self.drop(confidence: .dateOnly)], Self.drop(at: later)) == nil)
    }

    @Test("every drop comes back, in order, and only the moved one changes")
    func keepsTheRest() {
        let fresh = [Self.drop(4, at: Self.listed + Self.hour), Self.drop(5, at: Self.listed + 24 * Self.hour)]
        let carried = DelayDetection.carry(from: [Self.drop(4), Self.drop(5, at: Self.listed + 24 * Self.hour)],
                                           into: fresh)
        #expect(carried.map(\.id) == fresh.map(\.id))
        #expect(carried.map(\.previousDate) == [Self.listed, nil])
    }
}
