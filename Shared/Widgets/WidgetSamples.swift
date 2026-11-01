import Foundation

/// Sample moments for the widget previews and `WidgetRenderTests`: every state UI-BRIEF §6.1 lists. No artwork
/// (CLAUDE.md rule 9); the placeholder entry uses `.countdown`.
enum WidgetSamples {
    enum Case: String, CaseIterable, Sendable {
        /// Silo in 2 days 4 hours by Apple TV's usual time, then two more (3 rows).
        case countdown
        /// House of the Dragon in 3 hours, ticking, with no official stream here (2 rows).
        case ticking
        /// House of the Dragon came out 20 minutes ago.
        case outNow
        /// Wonder Man has a date but no time (1 row).
        case dateOnly
        /// Nothing followed.
        case nothing
        /// Nothing scheduled, but Silo returns on a known day.
        case returns
    }

    static func moment(_ sample: Case, now: Date) -> WidgetMoment {
        let hour: TimeInterval = 3_600
        let silo = drop("silo", "Silo", season: 3, number: 1, at: now + 52 * hour, confidence: .estimated,
                        source: .platformRule("Apple TV rule"), provider: ProviderLabel(name: "Apple TV", countryCode: nil,
                                                                                        noOfficialStream: false))
        let hotd = drop("hotd", "House of the Dragon", season: 3, number: 4, at: now + 3 * hour + 600, confidence: .exact,
                        source: .broadcast(network: "HBO"),
                        provider: ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: true))
        var hotdOut = hotd
        hotdOut.date = now - 1_200
        let frieren = drop("anilist:154587", "Frieren: Beyond Journey's End", season: 2, number: 3, at: now + 78 * hour,
                           confidence: .exact, source: .anilist,
                           provider: ProviderLabel(name: "Nippon TV", countryCode: "JP", noOfficialStream: false))
        let wonderMan = drop("wonderman", "Wonder Man", season: 1, number: 1, at: now + 9 * 24 * hour,
                             confidence: .dateOnly, source: .dateOnly, airdate: airdate(now + 9 * 24 * hour),
                             provider: ProviderLabel(name: "Disney+", countryCode: nil, noOfficialStream: false))
        let siloReturns = drop("silo", "Silo", season: 4, number: 1, at: now + 250 * 24 * hour,
                               confidence: .dateOnly, source: .dateOnly, airdate: "2027-07-09", provider: silo.provider)

        let drops: [Drop] = switch sample {
        case .countdown: [silo, frieren, wonderMan]
        case .ticking: [hotd, silo]
        case .outNow: [hotdOut, silo, frieren]
        case .dateOnly: [wonderMan]
        case .nothing, .returns: []
        }
        return WidgetTimeline.moment(at: now, drops: drops, nextReturn: sample == .returns ? siloReturns : nil)
    }

    private static func drop(_ showID: String, _ name: String, season: Int, number: Int, at date: Date,
                             confidence: Confidence, source: ReleaseSource, airdate: String? = nil,
                             provider: ProviderLabel?) -> Drop {
        Drop(id: "\(showID):s\(season)e\(number)", showID: showID, showName: name, season: season, number: number,
             episodeTitle: nil, date: date, airdate: airdate, confidence: confidence, source: source, provider: provider,
             previousDate: nil)
    }

    /// The listed day of a date-only sample, in UTC like TVmaze's `airdate`.
    private static func airdate(_ date: Date) -> String {
        DropFormatter(zoneIdentifier: "UTC").localDay(date)
    }
}
