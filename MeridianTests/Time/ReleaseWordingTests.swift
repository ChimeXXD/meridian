import Foundation
import Testing
@testable import Meridian

/// How sure a time is, said in words (D-40): the verb carries the certainty, and Show detail explains the source in
/// one sentence. Replaces the source chip and its colour code, which users couldn't read without help.
@Suite("Release wording")
struct ReleaseWordingTests {
    static let lagos = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
    /// Fri 30 Oct 2026, 18:00 in Lagos.
    static let now = Date(iso: "2026-10-30T17:00:00Z")
    /// 21:00 in Lagos the same day; 16:00 in New York (EDT).
    static let tonight = Date(iso: "2026-10-30T20:00:00Z")

    static func drop(_ source: ReleaseSource, _ confidence: Confidence, at date: Date = tonight,
                     airdate: String? = nil) -> Drop {
        Drop(id: "tvmaze:1:1x1", showID: "1", showName: "Show", season: 1, number: 1, episodeTitle: nil, date: date,
             airdate: airdate, confidence: confidence, source: source,
             provider: ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: false), previousDate: nil)
    }

    @Test("the verb says how sure the time is", arguments: [
        (ReleaseSource.broadcast(network: "HBO"), Confidence.exact, "Out today at 21:00"),
        (.override(note: "Marvel 18:00 PT"), .exact, "Out today at 21:00"),
        (.platformRule("Netflix rule"), .estimated, "Expected today at 21:00"),
        (.override(note: "Reported"), .estimated, "Expected today at 21:00"),
        (.adjusted(base: "JP broadcast", offsetMinutes: 30), .estimated, "Expected today at 21:00"),
        (.anilist, .exact, "Airs in Japan today at 21:00"),
    ])
    func verb(source: ReleaseSource, confidence: Confidence, expected: String) {
        #expect(ReleaseWording.outLine(Self.drop(source, confidence), now: Self.now, formatter: Self.lagos) == expected)
    }

    @Test("a date-only drop gives its listed day and says the time isn't announced (D-28)")
    func dateOnly() {
        let drop = Self.drop(.dateOnly, .dateOnly, airdate: "2026-11-19")
        #expect(ReleaseWording.outLine(drop, now: Self.now, formatter: Self.lagos) == "Out Thu 19 Nov, time not announced")
    }

    @Test("a date in another year says the year, so 2027 isn't read as this summer")
    func dateOnlyNextYear() {
        let drop = Self.drop(.dateOnly, .dateOnly, airdate: "2027-07-09")
        #expect(ReleaseWording.outLine(drop, now: Self.now, formatter: Self.lagos) == "Out Fri 9 Jul 2027, time not announced")
    }

    @Test("after the time, only a sure time says it was released", arguments: [
        (ReleaseSource.broadcast(network: "HBO"), Confidence.exact, "Released today at 16:00"),
        (.platformRule("Netflix rule"), .estimated, "Expected today at 16:00"),
        (.anilist, .exact, "Aired in Japan today at 16:00"),
    ])
    func past(source: ReleaseSource, confidence: Confidence, expected: String) {
        let drop = Self.drop(source, confidence, at: Date(iso: "2026-10-30T15:00:00Z"))
        #expect(ReleaseWording.outLine(drop, now: Self.now, formatter: Self.lagos) == expected)
    }

    @Test("naming adds the place whose clock the time is on, once per screen")
    func naming() {
        let line = ReleaseWording.outLine(Self.drop(.broadcast(network: "HBO"), .exact), now: Self.now,
                                          formatter: Self.lagos, naming: true)
        #expect(line == "Out today at 21:00 Lagos time")
    }

    @Test("zones are named by place; a zone with no city uses its correctly signed GMT name", arguments: [
        ("Africa/Lagos", "Lagos"), ("America/New_York", "New York"), ("Etc/GMT+1", "GMT-1"),
    ])
    func place(zone: String, expected: String) {
        #expect(ReleaseWording.place(DropFormatter(zoneIdentifier: zone)) == expected)
    }

    @Test("a show with nothing scheduled says why, and when it last aired", arguments: [
        ("Ended", "2025-03-29", "Ended · last episode Sat 29 Mar 2025"),
        ("FINISHED", "2025-03-29", "Ended · last episode Sat 29 Mar 2025"),
        ("Running", "2026-09-04", "Between seasons · last episode Fri 4 Sep"),
        ("HIATUS", nil, "On hiatus"),
        ("To Be Determined", nil, "Waiting for news"),
        ("NOT_YET_RELEASED", nil, "Not out yet"),
        (nil, nil, "No new episode announced"),
    ] as [(String?, String?, String)])
    func quietNote(status: String?, lastAired: String?, expected: String) {
        #expect(ReleaseWording.quietNote(status: status, lastAired: lastAired, formatter: Self.lagos, now: Self.now)
                == expected)
    }

    @Test("Welcome names the zone and its UTC offset", arguments: [
        ("Africa/Lagos", "Lagos, UTC+1"), ("Europe/London", "London, UTC+0"), ("Asia/Kolkata", "Kolkata, UTC+5:30"),
        ("America/New_York", "New York, UTC-4"),
    ])
    func zoneSummary(zone: String, expected: String) {
        #expect(ReleaseWording.zoneSummary(DropFormatter(zoneIdentifier: zone), at: Self.now) == expected)
    }

    @Test("Show detail explains where the time came from in one sentence", arguments: [
        (ReleaseSource.broadcast(network: "HBO"), Confidence.exact,
         "That's when HBO airs it in its home zone: Fri 16:00 New York time."),
        (.platformRule("Apple TV rule"), .estimated,
         "Apple TV doesn't publish release times, so this is when its new episodes usually arrive."),
        (.override(note: "Marvel 18:00 PT"), .exact, "This time was checked and confirmed."),
        (.override(note: "Reported"), .estimated, "This time was reported but isn't confirmed yet."),
        (.adjusted(base: "JP broadcast", offsetMinutes: -30), .estimated,
         "Your 30-minute adjustment is taken off the Japanese TV time."),
        (.anilist, .exact, "This is when it airs on Japanese TV. Streaming services may add it a little later."),
        (.dateOnly, .dateOnly, "Only the date is announced. The countdown starts once there's a time."),
    ])
    func explanation(source: ReleaseSource, confidence: Confidence, expected: String) {
        let drop = Self.drop(source, confidence)
        #expect(ReleaseWording.explanation(drop, broadcastZone: "America/New_York", formatter: Self.lagos) == expected)
    }

    @Test("a broadcast on the viewer's own clock doesn't repeat the time")
    func sameClock() {
        let newYork = DropFormatter(zoneIdentifier: "America/New_York", locale: Locale(identifier: "en_GB"))
        let drop = Self.drop(.broadcast(network: "HBO"), .exact)
        #expect(ReleaseWording.explanation(drop, broadcastZone: "America/New_York", formatter: newYork)
                == "That's when HBO airs it.")
    }
}
