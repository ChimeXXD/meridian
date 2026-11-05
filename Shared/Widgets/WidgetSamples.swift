import Foundation

/// Sample moments for the widget previews and `WidgetRenderTests`: every state UI-BRIEF §6.1 lists, and the worst
/// cases the layouts must survive. No artwork (CLAUDE.md rule 9); the placeholder entry uses `.countdown`.
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
        /// Six followed shows, five of them this week: more than any widget fits ("+2 more this week").
        case busy
        /// Two shows scheduled and three with nothing scheduled, which fill the spare rows.
        case quiet
        /// Three shows followed, none with a next episode.
        case allQuiet
    }

    /// Followed shows with no next episode, in follow order.
    static let quietShows = [
        QuietShow(showID: "from", name: "From", status: "Running", lastAired: "2025-06-22"),
        QuietShow(showID: "anilist:151807", name: "Solo Leveling", status: "FINISHED", lastAired: "2025-03-29"),
        QuietShow(showID: "tlou", name: "The Last of Us", status: "Running", lastAired: "2025-05-25"),
        QuietShow(showID: "andor", name: "Andor", status: "Ended", lastAired: "2025-05-13"),
    ]

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
                               confidence: .dateOnly, source: .dateOnly, airdate: airdate(now + 249 * 24 * hour),
                               provider: silo.provider)

        let severance = drop("severance", "Severance", season: 3, number: 2, at: now + 4 * 24 * hour,
                             confidence: .estimated, source: .platformRule("Apple TV rule"), provider: silo.provider)
        let bear = drop("bear", "The Bear", season: 5, number: 1, at: now + 5 * 24 * hour + 3 * hour,
                        confidence: .estimated, source: .platformRule("Hulu rule"),
                        provider: ProviderLabel(name: "Hulu", countryCode: "US", noOfficialStream: true))

        let drops: [Drop] = switch sample {
        case .countdown: [silo, frieren, wonderMan]
        case .ticking: [hotd, silo]
        case .outNow: [hotdOut, silo, frieren]
        case .dateOnly: [wonderMan]
        case .nothing, .returns, .allQuiet: []
        case .busy: [hotd, silo, frieren, severance, bear, wonderMan]
        case .quiet: [hotd, silo]
        }
        return WidgetTimeline.moment(at: now, drops: drops, nextReturn: sample == .returns ? siloReturns : nil,
                                     nothingScheduled: [.quiet, .allQuiet].contains(sample) ? quietShows : [])
    }

    /// Worst cases for the previews and the guard tests (break-ui, 5 Nov), kept out of `Case` so the design system
    /// shows the real states only.
    enum WorstCase: String, CaseIterable, Sendable {
        /// A 60-character name on "Paramount+ with Showtime · US" in 2 days, then a long name and a one-letter one.
        case longNames
        /// The long name ticking, then Japanese and Arabic names.
        case longTicking
        /// Over a year away: the top line needs its date and year.
        case farAway
        /// The long name just out.
        case longOutNow
    }

    static let longName = "Ascendance of a Bookworm: Adopted Daughter of an Archduke II"
    static let longProvider = ProviderLabel(name: "Paramount+ with Showtime", countryCode: "US", noOfficialStream: true)

    static func moment(_ worst: WorstCase, now: Date) -> WidgetMoment {
        let hour: TimeInterval = 3_600, day: TimeInterval = 86_400
        let prime = ProviderLabel(name: "Prime Video", countryCode: nil, noOfficialStream: false)
        let fx = ProviderLabel(name: "FX", countryCode: "US", noOfficialStream: false)
        let tokyoMX = ProviderLabel(name: "Tokyo MX", countryCode: "JP", noOfficialStream: false)
        let hbo = ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: true)
        func sure(_ id: String, _ name: String, in seconds: TimeInterval, _ provider: ProviderLabel) -> Drop {
            drop(id, name, season: 12, number: 104, at: now + seconds, confidence: .exact,
                 source: .broadcast(network: provider.name), provider: provider)
        }
        func guess(_ id: String, _ name: String, in seconds: TimeInterval, _ provider: ProviderLabel) -> Drop {
            drop(id, name, season: 1, number: 1, at: now + seconds, confidence: .estimated,
                 source: .platformRule("\(provider.name) rule"), provider: provider)
        }
        let lotr = guess("lotr", "The Lord of the Rings: The Rings of Power", in: 78 * hour, prime)
        let drops: [Drop] = switch worst {
        case .longNames:
            [sure("long", longName, in: 52 * hour, longProvider), lotr, sure("v", "V", in: 4 * day, fx)]
        case .longTicking:
            [sure("long", longName, in: 3 * hour + 600, longProvider),
             drop("anilist:1", "転生したらスライムだった件", season: nil, number: 24, at: now + 5 * hour,
                  confidence: .exact, source: .anilist, provider: tokyoMX),
             guess("rawabi", "مدرسة الروابي للبنات", in: 20 * hour,
                   ProviderLabel(name: "Netflix", countryCode: nil, noOfficialStream: false))]
        case .farAway:
            [sure("hotd", "House of the Dragon", in: 400 * day + 3 * hour, hbo),
             sure("tlou", "The Last of Us", in: 401 * day, hbo), sure("v", "V", in: 402 * day, fx)]
        case .longOutNow:
            [sure("long", longName, in: -60, longProvider), lotr]
        }
        return WidgetTimeline.moment(at: now, drops: drops, nextReturn: nil, nothingScheduled: [])
    }

    private static func drop(_ showID: String, _ name: String, season: Int?, number: Int?, at date: Date,
                             confidence: Confidence, source: ReleaseSource, airdate: String? = nil,
                             provider: ProviderLabel?) -> Drop {
        Drop(id: "\(showID):s\(season ?? 0)e\(number ?? 0)", showID: showID, showName: name, season: season,
             number: number, episodeTitle: nil, date: date, airdate: airdate, confidence: confidence, source: source, provider: provider,
             previousDate: nil)
    }

    /// The listed day of a date-only sample, in UTC like TVmaze's `airdate`.
    private static func airdate(_ date: Date) -> String {
        DropFormatter(zoneIdentifier: "UTC").localDay(date)
    }
}
