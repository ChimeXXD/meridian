import SwiftUI

/// The Dynamic Island's minimal presentation: the timer (SPEC §6). With room it is the ticking digits in moonlight.
/// When the system says the island is limited in width (`isDynamicIslandLimitedInWidth`, iOS 27) the digits can't
/// fit 28 pt, so it becomes a ring that empties over the last two hours, live, around the show's monogram. A coarse
/// "2h" would be text the system never updates, so it would be wrong an hour later.
struct LiveActivityMinimalView: View {
    let attributes: DropActivityAttributes
    let state: DropActivityAttributes.ContentState
    var isStale = false
    var limited = false
    var now = Date.now
    var formatter = DropFormatter()

    /// The most the minimal view may take when limited (SPEC §6).
    static let limitedWidth: CGFloat = 28
    /// The ring empties over this window before the drop: the default lead time, so it starts full.
    static let ringWindow = TimeInterval(LeadTime.defaultMinutes * 60)

    private var out: Bool { LiveActivityText.isOut(state, isStale: isStale, now: now) }

    var body: some View {
        content
            .accessibilityIdentifier("la-minimal")
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LiveActivityText.accessibilityLabel(attributes, state: state, isStale: isStale,
                                                                    now: now, formatter: formatter))
    }

    @ViewBuilder private var content: some View {
        if limited || out {
            ZStack {
                if out {
                    Circle().fill(LiveActivityInk.moonlight)
                    Text(LiveActivityText.monogram(attributes))
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(LiveActivityInk.bandOutText)
                } else {
                    ProgressView(timerInterval: state.dropDate.addingTimeInterval(-Self.ringWindow)...state.dropDate,
                                 countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.circular)
                    .tint(LiveActivityInk.moonlight)
                    Text(LiveActivityText.monogram(attributes))
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundStyle(LiveActivityInk.primary)
                }
            }
            .frame(width: 24, height: 24)
        } else {
            LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 12, tint: LiveActivityInk.moonlight,
                                  alignment: .center)
                .frame(maxWidth: 44)
        }
    }
}
