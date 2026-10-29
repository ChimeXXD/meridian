import Foundation

/// A resolved release time with its confidence and source.
struct Resolution: Hashable, Sendable {
    /// UTC instant. For `dateOnly` it's noon UTC on `airdate`, a sort key only.
    var date: Date
    var confidence: Confidence
    var source: ReleaseSource
    var airdate: String?
}
