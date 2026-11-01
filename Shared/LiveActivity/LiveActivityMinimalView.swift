import SwiftUI
import UIKit

/// The Dynamic Island's minimal presentation (#Yazio): the show's poster clipped to a circle, or its initial, inside a
/// ring that fills from when the activity started to the drop, live, and is full at "Out now". It is 24 pt, so it
/// fits the 28 pt the island allows when it is limited in width (SPEC §6). Digits would need a timeline to stay right
/// at this size; the ring moves on its own.
struct LiveActivityMinimalView: View {
    let attributes: DropActivityAttributes
    let state: DropActivityAttributes.ContentState
    var poster: UIImage?
    var isStale = false
    var now = Date.now
    var formatter = DropFormatter()

    /// The most the minimal view may take when the island is limited in width (SPEC §6).
    static let limitedWidth: CGFloat = 28
    static let diameter: CGFloat = 24

    private var out: Bool { LiveActivityText.isOut(state, isStale: isStale, now: now) }

    var body: some View {
        LiveActivityRing(window: attributes.window(until: state.dropDate), out: out, now: now,
                         diameter: Self.diameter) {
            LiveActivityPosterMark(attributes: attributes, poster: poster,
                                   size: Self.diameter - 2 * LiveActivityRing<EmptyView>.inset, shape: .circle)
        }
        .accessibilityIdentifier("la-minimal")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LiveActivityText.accessibilityLabel(attributes, state: state, isStale: isStale,
                                                                now: now, formatter: formatter))
    }
}
