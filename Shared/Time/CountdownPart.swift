import Foundation

/// One unit of a static countdown, e.g. the "2d" in "2d 4h". Views draw the value bright and the unit dim.
struct CountdownPart: Hashable, Sendable {
    enum Unit: String, Sendable {
        case day = "d", hour = "h", minute = "m"

        /// The unit as VoiceOver should say it, so "2d" is read "2 days", not "2 d".
        func spoken(_ value: Int) -> String {
            let word = switch self {
            case .day: "day"
            case .hour: "hour"
            case .minute: "minute"
            }
            return "\(value) \(word)\(value == 1 ? "" : "s")"
        }
    }

    var value: Int
    var unit: Unit
}
