import SwiftUI

extension TimelineSchedule where Self == PeriodicTimelineSchedule {
    /// The pace for any app view holding a ticking countdown. Inside a `TimelineView` a ticking
    /// `Text(timerInterval:)` only redraws at the timeline's pace, so `.everyMinute` froze every countdown (Chime,
    /// 1 Nov). Anchored on a whole second, so the digits change in step with the widgets and the Live Activity rather
    /// than up to a second late.
    static var countdown: PeriodicTimelineSchedule {
        .periodic(from: Date(timeIntervalSinceReferenceDate: Date.now.timeIntervalSinceReferenceDate.rounded(.down)),
                  by: 1)
    }
}
