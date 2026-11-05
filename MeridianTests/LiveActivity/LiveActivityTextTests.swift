import Foundation
import Testing
@testable import Meridian

/// The Live Activity's words (SPEC §6, UI-BRIEF §6.2): certainty in words (D-40), the provider with its country
/// (D-20), and the VoiceOver phrase built like the widgets' (CLAUDE.md accessibility rule). Times are on Lagos clocks.
@Suite("Live Activity text")
struct LiveActivityTextTests {
    static let lagos = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
    /// Fri 6 Nov 2026, 02:00 in Lagos.
    static let drop = Date(iso: "2026-11-06T01:00:00Z")
    /// Two hours before it.
    static let now = Date(iso: "2026-11-05T23:00:00Z")

    static func attributes(_ name: String = "Silo", episode: String = "S2E5", provider: String? = "Apple TV",
                           verb: ReleaseVerb = .out, drops: Int = 1) -> DropActivityAttributes {
        DropActivityAttributes(dropIDs: (1...drops).map { "tvmaze:44778:s2e\($0 + 4)" }, showName: name,
                               episodeLabel: episode, provider: provider, verb: verb)
    }

    static func state(_ phase: DropActivityAttributes.Phase = .upcoming, at date: Date = drop,
                      delayedFrom: Date? = nil) -> DropActivityAttributes.ContentState {
        .init(phase: phase, dropDate: date, delayedFrom: delayedFrom)
    }

    @Test("title: the show, or the first show plus how many more merged in")
    func title() {
        #expect(LiveActivityText.title(Self.attributes()) == "Silo")
        #expect(LiveActivityText.title(Self.attributes(drops: 2)) == "Silo + 1 more")
        #expect(LiveActivityText.title(Self.attributes(drops: 3)) == "Silo + 2 more")
    }

    @Test("details: episode · provider with its country, skipping empty parts")
    func details() {
        #expect(LiveActivityText.details(Self.attributes(provider: "Apple TV · US")) == "S2E5 · Apple TV · US")
        #expect(LiveActivityText.details(Self.attributes()) == "S2E5 · Apple TV")
        #expect(LiveActivityText.details(Self.attributes(episode: "")) == "Apple TV")
        #expect(LiveActivityText.details(Self.attributes(provider: nil)) == "S2E5")
        #expect(LiveActivityText.details(Self.attributes(episode: "", provider: "")) == "")
    }

    @Test("time line: the certainty verb, then the weekday and local time")
    func timeLine() {
        #expect(LiveActivityText.timeLine(Self.attributes(), dropDate: Self.drop, formatter: Self.lagos)
            == "Out Fri 02:00")
        #expect(LiveActivityText.timeLine(Self.attributes(verb: .expected), dropDate: Date(iso: "2026-11-04T22:00:00Z"),
                                          formatter: Self.lagos) == "Expected Wed 23:00")
        #expect(LiveActivityText.timeLine(Self.attributes("Frieren", verb: .airsInJapan),
                                          dropDate: Date(iso: "2026-11-06T14:00:00Z"), formatter: Self.lagos)
            == "Airs in Japan Fri 15:00")
    }

    @Test("alert: the title, then the lead, the local time and the provider; an estimate never 'starts'")
    func alert() {
        let sure = LiveActivityText.alert(Self.attributes(), leadMinutes: 120, dropDate: Self.drop, formatter: Self.lagos)
        #expect(sure.title == "Silo")
        #expect(sure.body == "Starts in 2 hours · 02:00 · Apple TV")

        let estimate = LiveActivityText.alert(Self.attributes(verb: .expected, drops: 2), leadMinutes: 60,
                                              dropDate: Self.drop, formatter: Self.lagos)
        #expect(estimate.title == "Silo + 1 more")
        #expect(estimate.body == "Expected in 1 hour · 02:00 · Apple TV")

        let anime = LiveActivityText.alert(Self.attributes("Frieren", provider: "Nippon TV · JP", verb: .airsInJapan),
                                           leadMinutes: 30, dropDate: Self.drop, formatter: Self.lagos)
        #expect(anime.body == "Airs in Japan in 30 minutes · 02:00 · Nippon TV · JP")

        let noProvider = LiveActivityText.alert(Self.attributes(provider: nil), leadMinutes: 360, dropDate: Self.drop,
                                                formatter: Self.lagos)
        #expect(noProvider.body == "Starts in 6 hours · 02:00")
    }

    @Test("VoiceOver: show, when (with its certainty), then the provider read without the dot")
    func accessibilityCountingDown() {
        func label(_ attributes: DropActivityAttributes, _ state: DropActivityAttributes.ContentState) -> String {
            LiveActivityText.accessibilityLabel(attributes, state: state, isStale: false, now: Self.now,
                                                formatter: Self.lagos)
        }
        #expect(label(Self.attributes(verb: .expected), Self.state()) == "Silo, expected in 2 hours, Apple TV")
        #expect(label(Self.attributes("House of the Dragon", episode: "S3E4", provider: "HBO · US"), Self.state())
            == "House of the Dragon, in 2 hours, HBO US")
        #expect(label(Self.attributes("Frieren: Beyond Journey's End", provider: "Nippon TV · JP", verb: .airsInJapan),
                      Self.state(at: Self.drop + 1_800))
            == "Frieren: Beyond Journey's End, airs in Japan in 2 hours 30 minutes, Nippon TV JP")
        #expect(label(Self.attributes(verb: .expected, drops: 2), Self.state())
            == "Silo and 1 more, expected in 2 hours, Apple TV")
        #expect(label(Self.attributes(provider: nil), Self.state()) == "Silo, in 2 hours")
    }

    @Test("VoiceOver: a provider with no official stream here says so, like the widgets (CLAUDE.md accessibility rule)")
    func accessibilityNoOfficialStream() {
        var hotd = Self.attributes("House of the Dragon", episode: "S3E4", provider: "HBO · US")
        hotd.noOfficialStream = true
        #expect(LiveActivityText.accessibilityLabel(hotd, state: Self.state(), isStale: false, now: Self.now,
                                                    formatter: Self.lagos)
            == "House of the Dragon, in 2 hours, HBO US, no official stream in your country")
    }

    @Test("VoiceOver: a moved time says where it moved from")
    func accessibilityDelayed() {
        let later = LiveActivityText.accessibilityLabel(Self.attributes(), state: Self.state(delayedFrom: Self.drop - 3_600),
                                                        isStale: false, now: Self.now, formatter: Self.lagos)
        #expect(later == "Silo, in 2 hours, delayed from Fri 01:00, Apple TV")
        let earlier = LiveActivityText.accessibilityLabel(Self.attributes(), state: Self.state(delayedFrom: Self.drop + 3_600),
                                                          isStale: false, now: Self.now, formatter: Self.lagos)
        #expect(earlier == "Silo, in 2 hours, moved from Fri 03:00, Apple TV")
        // Moved back to the listed time: nothing is struck through, so nothing is said.
        let unmoved = LiveActivityText.accessibilityLabel(Self.attributes(), state: Self.state(delayedFrom: Self.drop),
                                                          isStale: false, now: Self.now, formatter: Self.lagos)
        #expect(unmoved == "Silo, in 2 hours, Apple TV")
    }

    @Test("VoiceOver: out now when the phase says so, when the content is stale, or once the drop has passed")
    func accessibilityOutNow() {
        let attributes = Self.attributes()
        #expect(LiveActivityText.accessibilityLabel(attributes, state: Self.state(.outNow), isStale: false, now: Self.now,
                                                    formatter: Self.lagos) == "Silo, out now, Apple TV")
        #expect(LiveActivityText.accessibilityLabel(attributes, state: Self.state(), isStale: true, now: Self.now,
                                                    formatter: Self.lagos) == "Silo, out now, Apple TV")
        #expect(LiveActivityText.accessibilityLabel(attributes, state: Self.state(), isStale: false,
                                                    now: Self.drop + 60, formatter: Self.lagos) == "Silo, out now, Apple TV")
        // An estimate stays an estimate, as on the widgets, and the old time no longer matters.
        #expect(LiveActivityText.accessibilityLabel(Self.attributes(verb: .expected),
                                                    state: Self.state(delayedFrom: Self.drop - 3_600), isStale: true,
                                                    now: Self.now, formatter: Self.lagos) == "Silo, expected now, Apple TV")
        #expect(LiveActivityText.accessibilityLabel(Self.attributes("Frieren", provider: nil, verb: .airsInJapan),
                                                    state: Self.state(), isStale: true, now: Self.now,
                                                    formatter: Self.lagos) == "Frieren, just aired in Japan")
    }

    @Test("the band carries the certainty, then flips to Out now")
    func band() {
        #expect(LiveActivityText.band(Self.attributes(), out: false) == "Out in")
        #expect(LiveActivityText.band(Self.attributes(verb: .expected), out: false) == "Expected in")
        #expect(LiveActivityText.band(Self.attributes(verb: .airsInJapan), out: false) == "Airs in Japan in")
        #expect(LiveActivityText.band(Self.attributes(verb: .expected), out: true) == "Out now")
    }

    @Test("the struck-through old time, and the monogram")
    func pieces() {
        #expect(LiveActivityText.previousTime(Self.state(delayedFrom: Self.drop - 3_600), formatter: Self.lagos) == "01:00")
        // 23:00 Thursday in Lagos, the day before the new time.
        #expect(LiveActivityText.previousTime(Self.state(delayedFrom: Self.drop - 3 * 3_600), formatter: Self.lagos)
            == "Thu 23:00")
        #expect(LiveActivityText.previousTime(Self.state(), formatter: Self.lagos) == nil)
        #expect(LiveActivityText.previousTime(Self.state(delayedFrom: Self.drop), formatter: Self.lagos) == nil)
        #expect(LiveActivityText.monogram(Self.attributes()) == "S")
        #expect(LiveActivityText.monogram(Self.attributes("“Ghosts”")) == "G")
        // A title with no letter or digit shows its first character, not a bullet (break-ui BU-12).
        #expect(LiveActivityText.monogram(Self.attributes("💍")) == "💍")
        #expect(LiveActivityText.monogram(Self.attributes(" ")) == "•")
        #expect(LiveActivityText.more(Self.attributes()) == nil)
    }

    @Test("out line: the expanded island's time in words, by weekday so it can't go stale; past tense only when sure")
    func outLine() {
        let line = { (verb: ReleaseVerb, out: Bool) in
            LiveActivityText.outLine(Self.attributes(verb: verb), dropDate: Self.drop, out: out, formatter: Self.lagos)
        }
        #expect(line(.out, false) == "Out Fri 02:00")
        #expect(line(.expected, false) == "Expected Fri 02:00")
        #expect(line(.airsInJapan, false) == "Airs in Japan Fri 02:00")
        #expect(line(.out, true) == "Released Fri 02:00")
        #expect(line(.expected, true) == "Expected Fri 02:00")
        #expect(line(.airsInJapan, true) == "Aired in Japan Fri 02:00")
    }

    @Test("moved line: a delay or an earlier time in words, instead of a struck-through time")
    func movedLine() {
        #expect(LiveActivityText.movedLine(Self.state(delayedFrom: Self.drop - 3_600), formatter: Self.lagos)
            == "Delayed from 01:00")
        #expect(LiveActivityText.movedLine(Self.state(delayedFrom: Self.drop - 3 * 3_600), formatter: Self.lagos)
            == "Delayed from Thu 23:00")
        #expect(LiveActivityText.movedLine(Self.state(delayedFrom: Self.drop + 3_600), formatter: Self.lagos)
            == "Moved from 03:00")
        #expect(LiveActivityText.movedLine(Self.state(), formatter: Self.lagos) == nil)
        #expect(LiveActivityText.movedLine(Self.state(delayedFrom: Self.drop), formatter: Self.lagos) == nil)
    }
}
