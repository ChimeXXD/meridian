import SwiftUI
import UIKit

/// The Dynamic Island's two compact slots (UI-BRIEF §6.2): the show's poster in a small rounded square leading
/// (#Instagram), or its initial on a dark disc without one; the countdown trailing in white. At the drop the trailing
/// slot says "Out now" instead of a paused 0:00.
struct LiveActivityCompactView: View {
    enum Slot: Sendable { case leading, trailing }

    let slot: Slot
    let attributes: DropActivityAttributes
    let state: DropActivityAttributes.ContentState
    var poster: UIImage?
    var isStale = false
    var now = Date.now
    var formatter = DropFormatter()

    /// Wide enough for "1:59:59" in the slot's digits, so the island doesn't jump as the hours roll over.
    static let timerWidth: CGFloat = 60
    /// How far the timer may shrink inside that width: enough for "26:00:00", a running activity delayed by a day.
    static let timerMinimumScale: CGFloat = 0.7

    private var out: Bool { LiveActivityText.isOut(state, isStale: isStale, now: now) }

    var body: some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LiveActivityText.accessibilityLabel(attributes, state: state, isStale: isStale,
                                                                    now: now, formatter: formatter))
    }

    @ViewBuilder private var content: some View {
        switch slot {
        case .leading:
            LiveActivityPosterMark(attributes: attributes, poster: poster, size: 24, shape: .rounded)
                .accessibilityIdentifier("la-compact-poster")
        case .trailing:
            Group {
                if out {
                    Text("Out now")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LiveActivityInk.out)
                        .lineLimit(1)
                        .fixedSize()
                } else {
                    // A bound width and a scale, never `.fixedSize()`: on the phone a timer asks for its widest
                    // value's width (CLAUDE.md rule 4). Past 10 hours, or past a day once a running activity is
                    // delayed, the digits shrink to fit rather than being cut (break-ui BU-5).
                    LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 15, weight: .medium,
                                          alignment: .trailing)
                        .minimumScaleFactor(Self.timerMinimumScale)
                        .frame(maxWidth: Self.timerWidth, alignment: .trailing)
                }
            }
            .accessibilityIdentifier("la-compact-timer")
        }
    }
}
