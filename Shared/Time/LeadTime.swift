import Foundation

/// How long before a drop the release-night Live Activity starts (SPEC §1: 30 min to 6 h; default 2 h).
enum LeadTime {
    static let choices = [30, 60, 120, 180, 240, 360]
    static let defaultMinutes = 120
    /// The `UserDefaults` key. It moves to the App Group suite with the Live Activity scheduler (Day 5).
    static let storageKey = "leadMinutes"

    /// "1 minute", "30 minutes", "1 hour", "2 hours". The alert's lead can be a single minute once the chosen lead
    /// has passed (`ActivityPlanner`).
    static func phrase(minutes: Int) -> String {
        if minutes == 1 { return "1 minute" }
        guard minutes >= 60, minutes % 60 == 0 else { return "\(minutes) minutes" }
        let hours = minutes / 60
        return hours == 1 ? "1 hour" : "\(hours) hours"
    }
}
