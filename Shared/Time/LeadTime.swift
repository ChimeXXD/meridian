import Foundation

/// How long before a drop the release-night Live Activity starts (SPEC §1: 30 min to 6 h; default 2 h).
enum LeadTime {
    static let choices = [30, 60, 120, 180, 240, 360]
    static let defaultMinutes = 120
    /// The `UserDefaults` key. It moves to the App Group suite with the Live Activity scheduler (Day 5).
    static let storageKey = "leadMinutes"

    /// "30 minutes", "1 hour", "2 hours".
    static func phrase(minutes: Int) -> String {
        guard minutes >= 60, minutes % 60 == 0 else { return "\(minutes) minutes" }
        let hours = minutes / 60
        return hours == 1 ? "1 hour" : "\(hours) hours"
    }
}
