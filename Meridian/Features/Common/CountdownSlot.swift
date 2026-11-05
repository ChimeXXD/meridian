import SwiftUI

/// The app screens' countdown: the shared `CountdownText` (unchanged, so the widgets and the Live Activity keep their
/// own rules, D-52) in a slot that keeps its line's height and moves between states instead of cutting.
/// - At the drop, "Out now" (0.7 of the digits) would leave the line shorter and pull everything under it up 23 pt
///   (EA-2), so a hidden "0:00:00" in the digit font holds the height and the state sits on its bottom edge.
/// - "Out now" enters with a fade and a 0.97 scale from the reading edge on a fast-out curve (EA-2, AD-2); opacity
///   only under Reduce Motion.
/// - The still count's hourly step rolls (`.numericText`), keyed on the countdown's state, never on the second, so
///   the ticking digits never animate (EA-11). The 24 hour hand-off swaps one text for another, so it crossfades.
struct CountdownSlot: View {
    let drop: Date
    let confidence: Confidence
    var airdate: String?
    let now: Date
    var size: CGFloat
    var formatter = DropFormatter()
    /// `.leading` under a title, `.trailing` in a row's right-hand column.
    var alignment: HorizontalAlignment = .leading

    @Environment(\.numeralStudy) private var study
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The same growth as `CountdownText`, so the held height matches its digits at every text size.
    @ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1

    var body: some View {
        let state = CountdownFormatter.state(drop: drop, confidence: confidence, now: now)
        let isOut = state == .outNow || state == .released
        let anchor: UnitPoint = alignment == .trailing ? .trailing : .leading
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .bottom)) {
            Text(verbatim: "0:00:00")
                .font(study.font(size: size * scale))
                .lineLimit(1)
                .hidden()
            CountdownText(drop: drop, confidence: confidence, airdate: airdate, now: now, size: size, tint: .white,
                          formatter: formatter, alignment: Alignment(horizontal: alignment, vertical: .center))
                .contentTransition(.numericText(countsDown: true))
                .animation(.smooth(duration: 0.35), value: state)
                .id(isOut)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97, anchor: anchor)))
        }
        .animation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.4), value: isOut)
    }
}
