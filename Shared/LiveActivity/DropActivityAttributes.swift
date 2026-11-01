import ActivityKit
import Foundation

/// The release-night Live Activity (SPEC §6, D-10, D-24). Static attributes say which drops it covers and how to
/// name them; the content state is the drop time and whether it's out. Kept small: the payload must stay well under
/// 4 KB (CLAUDE.md rule 7), so it carries IDs, short strings and dates only, never art.
struct DropActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var phase: Phase
        /// The (earliest) drop's time, UTC (CLAUDE.md rule 1). The content's `staleDate` is this too, so the views
        /// show "Out now" at the drop without the app running.
        var dropDate: Date
        /// The time it was listed for before a delay, shown struck through.
        var delayedFrom: Date?
    }

    enum Phase: String, Codable, Hashable, Sendable {
        case upcoming, outNow
    }

    /// One or more merged same-night drops (`Drop.id`), soonest first. The scheduler matches activities by these.
    var dropIDs: [String]
    /// The first drop's show: "Silo".
    var showName: String
    /// "S2E5", or "" when the episode number isn't known.
    var episodeLabel: String
    /// `ProviderLabel.display`: "Apple TV", "HBO · US" (D-20).
    var provider: String?
    /// How sure the time is, in `ReleaseWording`'s verb: "Out", "Expected", "Airs in Japan" (D-40).
    var verb: String
}
