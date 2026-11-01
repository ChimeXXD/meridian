import Foundation
import Testing
@testable import Airstamp

/// The widgets' words (SPEC §5, UI-BRIEF §6.1, D-40), on Monday 2 Nov 2026 19:00 in Lagos.
@Suite("Widget text")
struct WidgetTextTests {
    static let now = Date(iso: "2026-11-02T18:00:00Z")
    static let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))

    static func moment(_ sample: WidgetSamples.Case) -> WidgetMoment { WidgetSamples.moment(sample, now: now) }

    @Test("inline: 'Silo · 2d 4h', Out now, the listed day, the follow prompt; a ticking count is left to the timer")
    func inline() {
        #expect(WidgetText.inline(Self.moment(.countdown), formatter: Self.formatter) == "Silo · 2d 4h")
        #expect(WidgetText.inline(Self.moment(.outNow), formatter: Self.formatter) == "House of the Dragon · Out now")
        #expect(WidgetText.inline(Self.moment(.dateOnly), formatter: Self.formatter) == "Wonder Man · Wed 11 Nov")
        #expect(WidgetText.inline(Self.moment(.nothing), formatter: Self.formatter) == "Follow a show")
        #expect(WidgetText.inline(Self.moment(.returns), formatter: Self.formatter) == "Silo returns Fri 9 Jul 2027")
        #expect(WidgetText.inline(Self.moment(.ticking), formatter: Self.formatter) == nil)
    }

    @Test("rectangular meta says how sure the time is and keeps the provider's country")
    func meta() throws {
        let silo = try #require(Self.moment(.countdown).current)
        #expect(WidgetText.meta(silo, now: Self.now, formatter: Self.formatter) == "Expected Wed 23:00 · Apple TV")
        let hotd = try #require(Self.moment(.ticking).current)
        #expect(WidgetText.meta(hotd, now: Self.now, formatter: Self.formatter) == "Out Mon 22:10 · HBO · US")
        let wonderMan = try #require(Self.moment(.dateOnly).current)
        #expect(WidgetText.meta(wonderMan, now: Self.now, formatter: Self.formatter) == "Time not announced · Disney+")
    }

    @Test("the out line is ReleaseWording's, except a date-only drop, whose day is already in the countdown's place")
    func outLine() throws {
        let silo = try #require(Self.moment(.countdown).current)
        #expect(WidgetText.outLine(silo, now: Self.now, formatter: Self.formatter) == "Expected Wed at 23:00")
        let wonderMan = try #require(Self.moment(.dateOnly).current)
        #expect(WidgetText.outLine(wonderMan, now: Self.now, formatter: Self.formatter) == "Time not announced")
    }

    @Test("the samples cover every state the brief lists")
    func samples() {
        let states = WidgetSamples.Case.allCases.map { Self.moment($0).state }
        #expect(Set(states) == [.countingDown, .outNow, .dateOnly, .nothing])
        #expect(Self.moment(.countdown).upNext.count == 3)
        #expect(Self.moment(.ticking).upNext.count == 2)
        #expect(Self.moment(.dateOnly).upNext.count == 1)
    }

    @Test("the circular ring is empty a week out and full at the drop")
    func ring() {
        #expect(CircularWidgetView.progress(to: Self.now + 8 * 86_400, now: Self.now) == 0)
        #expect(CircularWidgetView.progress(to: Self.now + 3.5 * 86_400, now: Self.now) == 0.5)
        #expect(CircularWidgetView.progress(to: Self.now, now: Self.now) == 1)
    }
}
