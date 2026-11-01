import SwiftUI

/// The Live Activity's ticking countdown in Night Sky's serif numerals, light by default. Always
/// `Text(timerInterval:pauseTime:countsDown:)`, paused at the drop, so it stops at 0:00 and never counts up
/// (CLAUDE.md rule 4). When the content goes stale at the drop the system redraws it paused, so the numbers stay put
/// while the label above flips to "Out now".
struct LiveActivityCountdown: View {
    let dropDate: Date
    var now = Date.now
    var size: CGFloat = 44
    var weight: Font.Weight = NumeralStudy.night.weight
    var tint: Color = LiveActivityInk.primary
    var alignment: TextAlignment = .leading

    var body: some View {
        // A range can't run backwards, so a drop already past starts and ends at the drop: it reads 0:00.
        // No `pauseTime`: with one the system drew this timer frozen at its first value (simulator Dynamic Island,
        // 1 Nov: 29:57 for 20 s; without it 19:56 → 19:51 in 5 s). The interval alone stops at 0:00 (rule 4).
        Text(timerInterval: min(now, dropDate)...dropDate, countsDown: true)
            .font(NumeralStudy.night.font(size: size, weight: weight))
            .foregroundStyle(tint)
            .multilineTextAlignment(alignment)
            .lineLimit(1)
    }
}
