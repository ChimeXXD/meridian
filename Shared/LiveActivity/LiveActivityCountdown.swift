import SwiftUI

/// The Live Activity's ticking countdown in Night Sky's light serif numerals. Always
/// `Text(timerInterval:pauseTime:countsDown:)`, paused at the drop, so it stops at 0:00 and never counts up
/// (CLAUDE.md rule 4). When the content goes stale at the drop the system redraws it paused, so the numbers stay put
/// while the band above flips to "Out now" (#146 Strava).
struct LiveActivityCountdown: View {
    let dropDate: Date
    var now = Date.now
    var size: CGFloat = 44
    var tint: Color = LiveActivityInk.primary
    var alignment: TextAlignment = .leading

    var body: some View {
        // A range can't run backwards, so a drop already past starts and ends at the drop: it reads 0:00.
        Text(timerInterval: min(now, dropDate)...dropDate, pauseTime: dropDate, countsDown: true)
            .font(NumeralStudy.night.font(size: size))
            .foregroundStyle(tint)
            .multilineTextAlignment(alignment)
            .lineLimit(1)
    }
}
