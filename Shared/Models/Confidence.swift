import Foundation

/// How sure we are of a drop's time (D-09). `dateOnly` drops never show a ticking timer.
enum Confidence: String, Codable, Sendable {
    case exact, estimated, dateOnly
}
