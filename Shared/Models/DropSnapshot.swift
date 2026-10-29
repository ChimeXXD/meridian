import Foundation

/// What the app writes to the App Group for the widgets and Live Activities (D-05).
struct DropSnapshot: Codable, Hashable, Sendable {
    var generatedAt: Date
    var drops: [Drop]
    /// The next real date for the empty state, e.g. "Silo returns 9 Jul 2027".
    var nextReturn: Drop?
}
