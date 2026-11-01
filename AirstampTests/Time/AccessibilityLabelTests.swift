import Foundation
import Testing
@testable import Airstamp

/// VoiceOver reads every widget and Live Activity as one full phrase built from the provider label (D4-5, CLAUDE.md
/// "Accessibility"): the show, when, then where. The certainty is said in words like `ReleaseWording` (D-40), and the
/// provider is never "on HBO" (D-20).
@Suite("Widget accessibility label")
struct AccessibilityLabelTests {
    static let lagos = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
    /// Fri 30 Oct 2026, 18:00 in Lagos.
    static let now = Date(iso: "2026-10-30T17:00:00Z")

    static let appleTV = ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false)
    static let hboBlocked = ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: true)
    static let crunchyroll = ProviderLabel(name: "Crunchyroll", countryCode: nil, noOfficialStream: false)

    static func drop(_ name: String, in seconds: TimeInterval, _ source: ReleaseSource, _ confidence: Confidence,
                     provider: ProviderLabel? = appleTV, airdate: String? = nil) -> Drop {
        Drop(id: "tvmaze:1:1", showID: "1", showName: name, season: 1, number: 1, episodeTitle: "Spoiler title",
             date: now.addingTimeInterval(seconds), airdate: airdate, confidence: confidence, source: source,
             provider: provider, previousDate: nil)
    }

    static func label(_ drop: Drop?) -> String {
        WidgetAccessibility.label(for: drop, now: now, formatter: lagos)
    }

    static let hours: TimeInterval = 3_600
    static let days: TimeInterval = 86_400

    @Test("an exact time reads as a plain countdown with the provider (the CLAUDE.md phrase)")
    func exact() {
        let drop = Self.drop("Silo", in: 2 * Self.days + 4 * Self.hours, .broadcast(network: "Apple TV"), .exact)
        #expect(Self.label(drop) == "Silo, in 2 days 4 hours, Apple TV")
    }

    @Test("a provider with no official stream here says so, with the country spoken plainly (the SPEC phrase)")
    func noOfficialStream() {
        let drop = Self.drop("House of the Dragon", in: 3 * Self.hours, .broadcast(network: "HBO"), .exact,
                             provider: Self.hboBlocked)
        #expect(Self.label(drop) == "House of the Dragon, in 3 hours, HBO US, no official stream in your country")
    }

    @Test("an estimate says expected, so VoiceOver claims no more than the screen", arguments: [
        ReleaseSource.platformRule("Apple TV rule"),
        .override(note: "Reported"),
        .adjusted(base: "JP broadcast", offsetMinutes: 30),
    ])
    func estimate(source: ReleaseSource) {
        let drop = Self.drop("Silo", in: 2 * Self.days + 4 * Self.hours, source, .estimated)
        #expect(Self.label(drop) == "Silo, expected in 2 days 4 hours, Apple TV")
    }

    @Test("an AniList time is the Japanese broadcast, and says so")
    func anilist() {
        let drop = Self.drop("Frieren", in: 5 * Self.hours + 30 * 60, .anilist, .exact, provider: Self.crunchyroll)
        #expect(Self.label(drop) == "Frieren, airs in Japan in 5 hours 30 minutes, Crunchyroll")
    }

    @Test("a date-only drop gives its listed day and no countdown (D-28)")
    func dateOnly() {
        let drop = Self.drop("The Bear", in: 20 * Self.days, .dateOnly, .dateOnly,
                             provider: ProviderLabel(name: "FX", countryCode: "US", noOfficialStream: false),
                             airdate: "2026-11-19")
        #expect(Self.label(drop) == "The Bear, out Thu 19 Nov, time not announced, FX US")
    }

    @Test("within the hour after the drop it is out now, worded by how sure the time was")
    func outNow() {
        #expect(Self.label(Self.drop("Silo", in: -10 * 60, .broadcast(network: "Apple TV"), .exact))
            == "Silo, out now, Apple TV")
        #expect(Self.label(Self.drop("Silo", in: 0, .broadcast(network: "Apple TV"), .exact)) == "Silo, out now, Apple TV")
        #expect(Self.label(Self.drop("Silo", in: -10 * 60, .platformRule("Apple TV rule"), .estimated))
            == "Silo, expected now, Apple TV")
        #expect(Self.label(Self.drop("Frieren", in: -10 * 60, .anilist, .exact, provider: Self.crunchyroll))
            == "Frieren, just aired in Japan, Crunchyroll")
    }

    @Test("more than an hour after the drop it reads like the out line, in the viewer's zone")
    func released() {
        #expect(Self.label(Self.drop("Silo", in: -2 * Self.hours, .broadcast(network: "Apple TV"), .exact))
            == "Silo, released today at 16:00, Apple TV")
        #expect(Self.label(Self.drop("Silo", in: -2 * Self.hours, .platformRule("Apple TV rule"), .estimated))
            == "Silo, expected today at 16:00, Apple TV")
    }

    @Test("nothing scheduled reads as one plain sentence")
    func nothing() {
        #expect(Self.label(nil) == "Nothing scheduled for your shows")
    }

    @Test("units are spoken in full and singular when one", arguments: [
        (TimeInterval(86_400), "Silo, in 1 day, Apple TV"),
        (TimeInterval(3_660), "Silo, in 1 hour 1 minute, Apple TV"),
        (TimeInterval(11_520), "Silo, in 3 hours 12 minutes, Apple TV"),
        (TimeInterval(20), "Silo, in 1 minute, Apple TV"),
    ])
    func units(seconds: TimeInterval, expected: String) {
        #expect(Self.label(Self.drop("Silo", in: seconds, .broadcast(network: "Apple TV"), .exact)) == expected)
    }

    @Test("no provider leaves the phrase at the show and its time")
    func noProvider() {
        let drop = Self.drop("Silo", in: 3 * Self.hours, .broadcast(network: "Apple TV"), .exact, provider: nil)
        #expect(Self.label(drop) == "Silo, in 3 hours")
    }

    @Test("never 'on HBO' (D-20) and never the episode title (spoiler-safe)")
    func neverOnOrTitle() {
        let drops = [
            Self.drop("House of the Dragon", in: 3 * Self.hours, .broadcast(network: "HBO"), .exact, provider: Self.hboBlocked),
            Self.drop("House of the Dragon", in: -10 * 60, .broadcast(network: "HBO"), .exact, provider: Self.hboBlocked),
            Self.drop("House of the Dragon", in: Self.days, .dateOnly, .dateOnly, provider: Self.hboBlocked,
                      airdate: "2026-10-31"),
        ]
        for drop in drops {
            let label = Self.label(drop)
            #expect(!label.lowercased().contains(" on "), "\(label)")
            #expect(!label.contains("Spoiler"), "\(label)")
        }
    }
}
