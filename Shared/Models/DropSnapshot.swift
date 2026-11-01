import Foundation

/// What the app writes to the App Group for the widgets and Live Activities (D-05).
struct DropSnapshot: Codable, Hashable, Sendable {
    var generatedAt: Date
    var drops: [Drop]
    /// The next real date for the empty state, e.g. "Silo returns 9 Jul 2027".
    var nextReturn: Drop?
    /// Followed shows with no next episode, in follow order, for the widgets' spare rows (D-48).
    var nothingScheduled: [QuietShow] = []
}

extension DropSnapshot {
    private enum CodingKeys: String, CodingKey {
        case generatedAt, drops, nextReturn, nothingScheduled
    }

    /// A snapshot written before `nothingScheduled` existed still reads, with none.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        drops = try container.decode([Drop].self, forKey: .drops)
        nextReturn = try container.decodeIfPresent(Drop.self, forKey: .nextReturn)
        nothingScheduled = try container.decodeIfPresent([QuietShow].self, forKey: .nothingScheduled) ?? []
    }
}
