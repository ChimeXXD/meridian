import Foundation
import Testing
@testable import Meridian

/// SPEC: "Report a wrong time" opens a prefilled email while the repo is private and a prefilled GitHub issue once
/// it's public; both carry show, episode, time shown, source and zone (D6-3, D-34). Each URL is decoded back and every
/// field checked, in both modes.
@Suite("Report a wrong time")
struct ReportURLBuilderTests {
    static let lagos = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
    /// Mon 2 Nov 2026, 19:00 in Lagos.
    static let now = Date(iso: "2026-11-02T18:00:00Z")

    static func drop(_ name: String = "House of the Dragon") -> Drop {
        Drop(id: "tvmaze:44778:3001", showID: "44778", showName: name, season: 3, number: 4, episodeTitle: nil,
             date: Date(iso: "2026-11-02T20:55:00Z"), airdate: nil, confidence: .exact,
             source: .broadcast(network: "HBO"), provider: ProviderLabel(name: "HBO", countryCode: "US",
                                                                      noOfficialStream: false),
             previousDate: nil, broadcastZone: "America/New_York")
    }

    static func query(_ url: URL) throws -> [String: String] {
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { first, _ in first })
    }

    static func expectFields(_ text: String) {
        #expect(text.contains("Show: House of the Dragon"))
        #expect(text.contains("Episode: S3E4"))
        #expect(text.contains("Time shown: Out today at 21:55 Lagos time (2026-11-02 20:55 UTC)"))
        #expect(text.contains("Where it came from: "))
        #expect(text.contains("Time zone: Lagos, UTC+1 (Africa/Lagos)"))
        #expect(text.contains("Episode ID: tvmaze:44778:3001"))
        #expect(text.contains("App: Meridian 0.1.0"))
    }

    @Test("while private: a mailto with the address, a subject naming the episode, and every field in the body")
    func email() throws {
        let url = try #require(ReportURLBuilder.url(for: Self.drop(), route: .email("me@example.com"), now: Self.now,
                                                    formatter: Self.lagos, appVersion: "0.1.0"))
        #expect(url.scheme == "mailto")
        #expect(URLComponents(url: url, resolvingAgainstBaseURL: false)?.path == "me@example.com")
        let query = try Self.query(url)
        #expect(query["subject"] == "Wrong time: House of the Dragon S3E4")
        Self.expectFields(try #require(query["body"]))
    }

    @Test("no address set: the email still opens, with no recipient")
    func emailWithoutAddress() throws {
        let url = try #require(ReportURLBuilder.url(for: Self.drop(), route: .email(""), now: Self.now,
                                                    formatter: Self.lagos, appVersion: "0.1.0"))
        #expect(url.absoluteString.hasPrefix("mailto:?"))
        Self.expectFields(try #require(Self.query(url)["body"]))
    }

    @Test("once public: a new GitHub issue on the repo with the same title and fields")
    func githubIssue() throws {
        let url = try #require(ReportURLBuilder.url(for: Self.drop(), route: .githubIssue, now: Self.now,
                                                    formatter: Self.lagos, appVersion: "0.1.0"))
        #expect(url.host == "github.com" && url.path == "/ChimeXXD/meridian/issues/new")
        let query = try Self.query(url)
        #expect(query["title"] == "Wrong time: House of the Dragon S3E4")
        Self.expectFields(try #require(query["body"]))
    }

    @Test("a name with & = + # ? survives the round trip, in both modes")
    func awkwardName() throws {
        let name = "Law & Order = SVU + #1?"
        for route in [ReportRoute.email("me@example.com"), .githubIssue] {
            let url = try #require(ReportURLBuilder.url(for: Self.drop(name), route: route, now: Self.now,
                                                        formatter: Self.lagos, appVersion: "0.1.0"))
            let query = try Self.query(url)
            #expect((query["subject"] ?? query["title"]) == "Wrong time: \(name) S3E4")
            #expect(query["body"]?.contains("Show: \(name)\n") == true)
        }
    }
}
