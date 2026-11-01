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
                    LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 15, weight: .medium,
                                          alignment: .trailing)
                        .frame(maxWidth: Self.timerWidth, alignment: .trailing)
                }
            }
            .accessibilityIdentifier("la-compact-timer")
        }
    }
}
