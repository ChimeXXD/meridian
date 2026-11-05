import Foundation

/// Sample Live Activities for the previews and `LiveActivityLayoutTests`: every state UI-BRIEF §6.2 lists. No artwork
/// is committed (CLAUDE.md rule 9): the tests pass neutral placeholders. Each
/// activity started 40 minutes before `now`, so its ring is partly filled.
enum LiveActivitySamples {
    enum Case: String, CaseIterable, Sendable {
        /// Silo S2E5 by Apple TV's usual time, in 2 hours: an estimate, so "Expected".
        case countingDown
        /// Frieren's Japanese TV time, the longest name the samples use.
        case longName
        /// Silo and House of the Dragon on the same night, merged into one activity.
        case merged
        /// House of the Dragon moved an hour later; the old time is struck through.
        case delayed
        /// Silo came out 10 minutes ago.
        case outNow
    }

    static func attributes(_ sample: Case, now: Date = .now) -> DropActivityAttributes {
        var attributes = switch sample {
        case .countingDown, .outNow:
            silo
        case .longName:
            DropActivityAttributes(dropIDs: ["anilist:154587:s2e3"], showName: "Frieren: Beyond Journey's End",
                                   episodeLabel: "S2E3", provider: "Nippon TV · JP", verb: .airsInJapan,
                                   showID: "anilist:154587")
        case .merged:
            DropActivityAttributes(dropIDs: [silo.dropIDs[0], hotd.dropIDs[0]], showName: silo.showName,
                                   episodeLabel: silo.episodeLabel, provider: silo.provider, verb: silo.verb,
                                   showID: silo.showID)
        case .delayed:
            hotd
        }
        attributes.windowStart = now - 40 * 60
        return attributes
    }

    static func state(_ sample: Case, now: Date) -> DropActivityAttributes.ContentState {
        let hour: TimeInterval = 3_600
        return switch sample {
        case .countingDown, .longName, .merged:
            .init(phase: .upcoming, dropDate: now + 2 * hour, delayedFrom: nil)
        case .delayed:
            .init(phase: .upcoming, dropDate: now + 3 * hour, delayedFrom: now + 2 * hour)
        case .outNow:
            .init(phase: .outNow, dropDate: now - 600, delayedFrom: nil)
        }
    }

    private static let silo = DropActivityAttributes(dropIDs: ["tvmaze:44778:s2e5"], showName: "Silo",
                                                     episodeLabel: "S2E5", provider: "Apple TV", verb: .expected,
                                                     showID: "44778")
    private static let hotd = DropActivityAttributes(dropIDs: ["tvmaze:44229:s3e4"], showName: "House of the Dragon",
                                                     episodeLabel: "S3E4", provider: "HBO · US", verb: .out,
                                                     showID: "44229")
}
