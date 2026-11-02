import ActivityKit
import Foundation

/// The release-night Live Activity (SPEC §6, D-10, D-24). Static attributes say which drops it covers and how to
/// name them; the content state is the drop time and whether it's out. Kept small: the payload must stay well under
/// 4 KB (CLAUDE.md rule 7), so it carries IDs, short strings and dates only, never art. The views find the show's art
/// in the App Group by `showID`.
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
    /// `ProviderLabel.noOfficialStream`: VoiceOver adds "no official stream in your country", as the widgets do.
    var noOfficialStream = false
    /// The first drop's show (`Drop.showID`), to find its art in the App Group; "" when there's none to find.
    var showID = ""
    /// When the activity starts, so the minimal island's ring fills from here to the drop. Nil falls back to
    /// `defaultWindow` before the drop.
    var windowStart: Date?

    /// How long the ring takes to fill when the start isn't known: the default lead time.
    static let defaultWindow = TimeInterval(LeadTime.defaultMinutes * 60)

    /// The span the ring fills over, ending at the drop. Never empty or reversed, because
    /// `ProgressView(timerInterval:)` needs a forward range; a start at or after the drop (it was moved earlier)
    /// becomes a minute before it.
    func window(until dropDate: Date) -> ClosedRange<Date> {
        let start = windowStart ?? dropDate.addingTimeInterval(-Self.defaultWindow)
        return min(start, dropDate.addingTimeInterval(-60))...dropDate
    }
}

extension DropActivityAttributes {
    /// Decodes attributes written before a field existed (an activity still pending from an older build) with that
    /// field's default, rather than failing to draw it.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dropIDs = try container.decode([String].self, forKey: .dropIDs)
        showName = try container.decode(String.self, forKey: .showName)
        episodeLabel = try container.decodeIfPresent(String.self, forKey: .episodeLabel) ?? ""
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        verb = try container.decodeIfPresent(String.self, forKey: .verb) ?? ""
        noOfficialStream = try container.decodeIfPresent(Bool.self, forKey: .noOfficialStream) ?? false
        showID = try container.decodeIfPresent(String.self, forKey: .showID) ?? ""
        windowStart = try container.decodeIfPresent(Date.self, forKey: .windowStart)
    }
}
