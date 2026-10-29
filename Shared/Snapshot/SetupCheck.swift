import Foundation

/// Day 0 proof that the app and the widget share storage: the app writes a timestamp,
/// the widget reads it. Replaced by `SnapshotStore` on Day 4.
enum SetupCheck {
    static let key = "setupCheck.writtenAt"

    static func write(_ date: Date = .now, to defaults: UserDefaults) {
        defaults.set(date.timeIntervalSince1970, forKey: key)
    }

    static func read(from defaults: UserDefaults) -> Date? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return Date(timeIntervalSince1970: defaults.double(forKey: key))
    }
}
