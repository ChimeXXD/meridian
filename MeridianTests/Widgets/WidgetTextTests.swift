import Foundation
import Testing
@testable import Meridian

/// The widgets' words (SPEC §5, UI-BRIEF §6.1, D-40), on Monday 2 Nov 2026 19:00 in Lagos.
@Suite("Widget text")
struct WidgetTextTests {
    static let now = Date(iso: "2026-11-02T18:00:00Z")
    static let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))

    static func moment(_ sample: WidgetSamples.Case) -> WidgetMoment { WidgetSamples.moment(sample, now: now) }

    @Test("inline: 'Silo · 2d 4h' days away, Out now, the listed day, the follow prompt; the last day is left to the timer")
    func inline() {
        // More than a day away the count stands still (Chime, 2 Nov); within a day the view adds the live timer.
        #expect(WidgetText.inline(Self.moment(.countdown), formatter: Self.formatter) == "Silo · 2d 4h")
        // "House of the Dragon · Out now" is a little wider than the narrowest Lock Screen: the name gives way.
        #expect(WidgetText.inline(Self.moment(.outNow), formatter: Self.formatter) == "House of the Drag… · Out now")
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
        #expect(WidgetText.when(hotd, now: Self.now, formatter: Self.formatter) == "Out today 22:10")
        let hotdOut = try #require(Self.moment(.outNow).current)
        #expect(WidgetText.when(hotdOut, now: Self.now, formatter: Self.formatter) == "Released today 18:40")
        let wonderMan = try #require(Self.moment(.dateOnly).current)
        #expect(WidgetText.when(wonderMan, now: Self.now, formatter: Self.formatter) == "Time not announced")
    }

    /// A drop `seconds` from `now`, with a sure time unless told otherwise.
    static func drop(_ name: String, in seconds: TimeInterval, _ confidence: Confidence = .exact) -> Drop {
        let date = now + seconds
        return Drop(id: "x:s1e1", showID: "x", showName: name, season: 1, number: 1, episodeTitle: nil, date: date,
                    airdate: confidence == .dateOnly ? formatter.localDay(date) : nil, confidence: confidence,
                    source: confidence == .dateOnly ? .dateOnly : .broadcast(network: "HBO"), provider: nil,
                    previousDate: nil)
    }

    static let longName = "Ascendance of a Bookworm: Adopted Daughter of an Archduke II"

    @Test("top line: today and tomorrow, the weekday for 2 to 6 days, then the date, with the year when it differs")
    func whenFarAway() {
        let day: TimeInterval = 86_400
        #expect(WidgetText.when(Self.drop("Silo", in: day), now: Self.now, formatter: Self.formatter)
            == "Out tomorrow 19:00")
        #expect(WidgetText.when(Self.drop("Silo", in: 6 * day), now: Self.now, formatter: Self.formatter)
            == "Out Sun 19:00")
        // A weekday alone a week or more away named the wrong week (break-ui BU-2).
        #expect(WidgetText.when(Self.drop("Silo", in: 9 * day), now: Self.now, formatter: Self.formatter)
            == "Out Wed 11 Nov 19:00")
        #expect(WidgetText.when(Self.drop("Silo", in: 400 * day), now: Self.now, formatter: Self.formatter)
            == "Out Tue 7 Dec 2027 19:00")
    }

    /// The inline line as the moment draws it, on the widget's own clock.
    static func inlineLine(_ drops: [Drop], returning back: Drop? = nil) -> String? {
        WidgetText.inline(WidgetTimeline.moment(at: now, drops: drops, nextReturn: back, nothingScheduled: [],
                                                formatter: formatter), formatter: formatter)
    }

    /// Whether a line fits the narrowest inline widget, with its ending intact.
    static func fits(_ line: String, endingWith ending: String) -> Bool {
        line.hasSuffix(ending) && WidgetText.inlineTextWidth(line) <= WidgetText.inlineWidth
    }

    @Test("inline: a long name shortens, and the count, 'Out now' or the day after it always stays (break-ui BU-1)")
    func inlineLongName() throws {
        let counting = try #require(Self.inlineLine([Self.drop(Self.longName, in: 52 * 3_600)]))
        #expect(counting.hasPrefix("Ascendance of a") && Self.fits(counting, endingWith: "… · 2d 4h"), "\(counting)")
        let out = try #require(Self.inlineLine([Self.drop(Self.longName, in: -60)]))
        #expect(Self.fits(out, endingWith: "… · Out now"), "\(out)")
        let dateOnly = try #require(Self.inlineLine([Self.drop(Self.longName, in: 9 * 86_400, .dateOnly)]))
        #expect(Self.fits(dateOnly, endingWith: "… · Wed 11 Nov"), "\(dateOnly)")
        let far = try #require(Self.inlineLine([Self.drop(Self.longName, in: 400 * 86_400)]))
        #expect(Self.fits(far, endingWith: "… · 400d 0h"), "\(far)")
        let back = Self.drop(Self.longName, in: 250 * 86_400, .dateOnly)
        let returns = try #require(Self.inlineLine([], returning: back))
        #expect(Self.fits(returns, endingWith: "… returns Sat 10 Jul 2027"), "\(returns)")
        // The last day's line is the name and a live timer: the name leaves room for the timer's widest value.
        let ticking = WidgetText.inlineName(Self.longName, before: " · 00:00:00")
        #expect(Self.fits(ticking + " · 00:00:00", endingWith: "… · 00:00:00"), "\(ticking)")
        // A name that fits is left whole.
        #expect(WidgetText.inlineName("Silo", before: " · 00:00:00") == "Silo")
        #expect(WidgetText.inlineName("House of the Dragon", before: " · 2d 4h") == "House of the Dragon")
    }

    @Test("following shows with nothing scheduled says so, never 'Follow a show'")
    func allQuiet() {
        let moment = Self.moment(.allQuiet)
        #expect(moment.state == .nothing)
        #expect(WidgetText.emptyHeadline(moment, formatter: Self.formatter) == "Nothing scheduled")
        #expect(WidgetText.emptyDetail(moment) == "Meridian checks again each time you open it.")
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
