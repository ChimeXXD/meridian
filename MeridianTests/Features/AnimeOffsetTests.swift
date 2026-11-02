import Foundation
import Testing
@testable import Meridian

/// SPEC §3.1 and Show detail's `detail-offset` (UX audit #5, a Must): an anime's stream can follow its Japanese TV
/// time by a set delay. The control says the delay in words and appears only for anime.
@Suite("Anime offset")
struct AnimeOffsetTests {
    static func drop(_ source: ReleaseSource) -> Drop {
        Drop(id: "anilist:154587:8", showID: "anilist:154587", showName: "Frieren", season: 2, number: 8,
             episodeTitle: nil, date: .now, airdate: nil, confidence: .exact, source: source, provider: nil,
             previousDate: nil)
    }

    @Test("the delay in words: the same time, minutes, then hours and minutes")
    func phrase() {
        #expect(AnimeOffset.phrase(0) == "Same time as Japan")
        #expect(AnimeOffset.phrase(15) == "15 min after Japan")
        #expect(AnimeOffset.phrase(60) == "1 h after Japan")
        #expect(AnimeOffset.phrase(90) == "1 h 30 min after Japan")
        #expect(AnimeOffset.phrase(180) == "3 h after Japan")
    }

    @Test("steps of 15 minutes, from none to 3 hours")
    func range() {
        #expect(AnimeOffset.range == 0...180)
        #expect(AnimeOffset.step == 15)
    }

    @Test("only anime get the control: an AniList show, or a time already adjusted from Japan's")
    func onlyAnime() {
        #expect(AnimeOffset.applies(to: Self.drop(.anilist), catalog: .anilist))
        #expect(AnimeOffset.applies(to: Self.drop(.adjusted(base: "JP broadcast", offsetMinutes: 30)), catalog: .tvmaze))
        #expect(!AnimeOffset.applies(to: Self.drop(.broadcast(network: "HBO")), catalog: .tvmaze))
        #expect(!AnimeOffset.applies(to: Self.drop(.platformRule("Netflix rule")), catalog: .tvmaze))
    }
}
