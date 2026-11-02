import SwiftUI

extension EnvironmentValues {
    /// Draws the ring as a plain shape, at its fill for the view's `now`, instead of the system's live
    /// `ProgressView(timerInterval:)`. `ImageRenderer` can't draw the system's progress views, so
    /// `LiveActivityLayoutTests` turns this on to see it; the Live Activity never does, because a shape would freeze
    /// at the moment the view was drawn.
    @Entry var liveActivityStaticProgress = false
}

extension ClosedRange<Date> {
    /// How far `now` is through the range, 0 to 1.
    func fraction(at now: Date) -> Double {
        let span = upperBound.timeIntervalSince(lowerBound)
        guard span > 0 else { return 1 }
        return Swift.min(1, Swift.max(0, now.timeIntervalSince(lowerBound) / span))
    }
}
