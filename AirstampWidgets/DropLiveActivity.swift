import ActivityKit
import SwiftUI
import WidgetKit

/// The release-night Live Activity (SPEC §6, UI-BRIEF §6.2): the Lock Screen banner, the Dynamic Island's compact,
/// minimal and expanded presentations, and the `.small` family for the Watch Smart Stack, Mac menu bar and CarPlay.
/// The views live in `Shared/LiveActivity` so the app's tests can render them; this file only wires them to the
/// activity's context. "Out now" shows once the content is stale at the drop, without the app (`context.isStale`).
struct DropLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DropActivityAttributes.self) { context in
            DropLiveActivityContent(context: context)
                .activityBackgroundTint(LiveActivityInk.base)
                .activitySystemActionForegroundColor(LiveActivityInk.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityExpandedView(region: .leading, attributes: context.attributes, state: context.state,
                                             isStale: context.isStale)
                        .dynamicIsland(verticalPlacement: .belowIfTooWide)
                        .padding(.leading, Tokens.Space.xxs)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveActivityExpandedView(region: .trailing, attributes: context.attributes, state: context.state,
                                             isStale: context.isStale)
                        .padding(.trailing, Tokens.Space.xxs)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityExpandedView(region: .bottom, attributes: context.attributes, state: context.state,
                                             isStale: context.isStale)
                        .padding(.horizontal, Tokens.Space.xxs)
                }
            } compactLeading: {
                LiveActivityCompactView(slot: .leading, attributes: context.attributes, state: context.state,
                                        isStale: context.isStale)
            } compactTrailing: {
                LiveActivityCompactView(slot: .trailing, attributes: context.attributes, state: context.state,
                                        isStale: context.isStale)
            } minimal: {
                DropLiveActivityMinimal(context: context)
            }
            .keylineTint(LiveActivityInk.moonlight)
        }
        .supplementalActivityFamilies([.small])
    }
}

/// Picks the Lock Screen banner or, in the `.small` family, the shorter view.
private struct DropLiveActivityContent: View {
    let context: ActivityViewContext<DropActivityAttributes>

    @Environment(\.activityFamily) private var family

    var body: some View {
        switch family {
        case .small:
            LiveActivitySmallView(attributes: context.attributes, state: context.state, isStale: context.isStale)
                .padding(Tokens.Space.s)
        default:
            LiveActivityLockScreenView(attributes: context.attributes, state: context.state, isStale: context.isStale)
        }
    }
}

/// The minimal view, told whether the island is limited in width. That flag is new in iOS 27; on iOS 26 the minimal
/// view assumes it has room.
private struct DropLiveActivityMinimal: View {
    let context: ActivityViewContext<DropActivityAttributes>

    var body: some View {
        if #available(iOS 27.0, *) {
            LimitedWidthReader { limited in
                LiveActivityMinimalView(attributes: context.attributes, state: context.state, isStale: context.isStale,
                                        limited: limited)
            }
        } else {
            LiveActivityMinimalView(attributes: context.attributes, state: context.state, isStale: context.isStale)
        }
    }
}

@available(iOS 27.0, *)
private struct LimitedWidthReader<Content: View>: View {
    @ViewBuilder let content: (Bool) -> Content

    @Environment(\.isDynamicIslandLimitedInWidth) private var limited

    var body: some View {
        content(limited)
    }
}
