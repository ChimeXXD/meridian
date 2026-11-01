import SwiftUI
import UIKit

/// The `.small` activity family (SPEC §6: Watch Smart Stack, Mac menu bar, CarPlay): the poster mark and the title in
/// serif, the label's words over the countdown, and the local time. Same words as the Lock Screen, fewer of them.
struct LiveActivitySmallView: View {
    let attributes: DropActivityAttributes
    let state: DropActivityAttributes.ContentState
    var poster: UIImage?
    var isStale = false
    var now = Date.now
    var formatter = DropFormatter()

    private var out: Bool { LiveActivityText.isOut(state, isStale: isStale, now: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                LiveActivityPosterMark(attributes: attributes, poster: poster, size: 18)
                Text(LiveActivityText.title(attributes))
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(LiveActivityInk.primary)
                    .lineLimit(1)
                    .accessibilityIdentifier("la-small-title")
            }
            .padding(.bottom, 2)
            Text(LiveActivityText.band(attributes, out: out))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(out ? LiveActivityInk.primary : LiveActivityInk.muted)
                .lineLimit(1)
            LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 24)
                .accessibilityIdentifier("la-small-countdown")
            Text(LiveActivityText.timeLine(attributes, dropDate: state.dropDate, formatter: formatter))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LiveActivityInk.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LiveActivityText.accessibilityLabel(attributes, state: state, isStale: isStale, now: now,
                                                                formatter: formatter))
    }
}
