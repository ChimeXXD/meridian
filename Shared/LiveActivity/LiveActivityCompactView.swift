import SwiftUI

/// The Dynamic Island's two compact slots (UI-BRIEF §6.2, #132 Flighty): the show's monogram leading, the countdown
/// trailing in moonlight. At the drop the trailing slot says "Out now" instead of a paused 0:00.
struct LiveActivityCompactView: View {
    enum Slot: Sendable { case leading, trailing }

    let slot: Slot
    let attributes: DropActivityAttributes
    let state: DropActivityAttributes.ContentState
    var isStale = false
    var now = Date.now
    var formatter = DropFormatter()

    /// Wide enough for "1:59:59" in the slot's digits, so the island doesn't jump as the hours roll over.
    static let timerWidth: CGFloat = 62

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
            LiveActivityMonogram(attributes: attributes, diameter: 24)
                .accessibilityIdentifier("la-compact-monogram")
        case .trailing:
            Group {
                if out {
                    Text("Out now")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LiveActivityInk.moonlight)
                        .lineLimit(1)
                } else {
                    LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 15,
                                          tint: LiveActivityInk.moonlight, alignment: .trailing)
                }
            }
            .frame(maxWidth: Self.timerWidth, alignment: .trailing)
            .accessibilityIdentifier("la-compact-timer")
        }
    }
}
