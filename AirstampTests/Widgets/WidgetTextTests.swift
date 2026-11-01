import Foundation
import Testing
@testable import Airstamp

/// The widgets' words (SPEC §5, UI-BRIEF §6.1, D-40), on Monday 2 Nov 2026 19:00 in Lagos.
@Suite("Widget text")
struct WidgetTextTests {
    static let now = Date(iso: "2026-11-02T18:00:00Z")
    static let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))

    static func moment(_ sample: WidgetSamples.Case) -> WidgetMoment { WidgetSamples.moment(sample, now: now) }

    @Test("inline: Out now, the listed day, the follow prompt; any count, days away too, is left to the live timer")
    func inline() {
        // Counting down, the line ticks live (the view adds the timer), days away too.
        #expect(WidgetText.inline(Self.moment(.countdown), formatter: Self.formatter) == nil)
        #expect(WidgetText.inline(Self.moment(.outNow), formatter: Self.formatter) == "House of the Dragon · Out now")
        #expect(WidgetText.inline(Self.moment(.dateOnly), formatter: Self.formatter) == "Wonder Man · Wed 11 Nov")
        #expect(WidgetText.inline(Self.moment(.nothing), formatter: Self.formatter) == "Follow a show")
        #expect(WidgetText.inline(Self.moment(.returns), formatter: Self.formatter) == "Silo returns Fri 9 Jul 2027")
        #expect(WidgetText.inline(Self.moment(.ticking), formatter: Self.formatter) == nil)
    }

    @Test("rectangular top line leads with how sure the time is, without the provider (#Udemy)")
    func when() throws {
        let silo = try #require(Self.moment(.countdown).current)
        #expect(WidgetText.when(silo, now: Self.now, formatter: Self.formatter) == "Expected Wed 23:00")
        let hotd = try #require(Self.moment(.ticking).current)
        #expect(WidgetText.when(hotd, now: Self.now, formatter: Self.formatter) == "Out Mon 22:10")
        let hotdOut = try #require(Self.moment(.outNow).current)
        #expect(WidgetText.when(hotdOut, now: Self.now, formatter: Self.formatter) == "Released Mon 18:40")
        let wonderMan = try #require(Self.moment(.dateOnly).current)
        #expect(WidgetText.when(wonderMan, now: Self.now, formatter: Self.formatter) == "Time not announced")
    }

    @Test("following shows with nothing scheduled says so, never 'Follow a show'")
    func allQuiet() {
        let moment = Self.moment(.allQuiet)
        #expect(moment.state == .nothing)
        #expect(WidgetText.emptyHeadline(moment, formatter: Self.formatter) == "Nothing scheduled")
        #expect(WidgetText.emptyDetail(moment) == "Airstamp checks again each time you open it.")
        #expect(WidgetText.inline(moment, formatter: Self.formatter) == "Nothing scheduled")
        #expect(WidgetText.emptyHeadline(Self.moment(.nothing), formatter: Self.formatter) == "Follow a show")
    }

    @Test("the tag for shows that don't fit: '+3 more this week', none when all fit")
    func more() {
        #expect(WidgetText.more(3) == "+3 more this week")
        #expect(WidgetText.more(1) == "+1 more this week")
        #expect(WidgetText.more(0) == nil)
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
