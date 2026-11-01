import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

/// The release-night Live Activity (SPEC §6, UI-BRIEF §6.2): the Lock Screen banner, the Dynamic Island's compact,
/// minimal and expanded presentations, and the `.small` family for the Watch Smart Stack, Mac menu bar and CarPlay.
/// The views live in `Shared/LiveActivity` so the app's tests can render them; this file wires them to the activity's
/// context and loads the show's art the app saved in the App Group. "Out now" shows once the content is stale at the
/// drop, without the app (`context.isStale`).
struct DropLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DropActivityAttributes.self) { context in
            DropLiveActivityContent(context: context)
                .activityBackgroundTint(LiveActivityInk.base)
                .activitySystemActionForegroundColor(LiveActivityInk.primary)
        } dynamicIsland: { context in
            // Read once for every presentation, not once per region.
            let poster = ActivityArt.poster(context.attributes)
            let hero = ActivityArt.hero(context.attributes)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityExpandedView(region: .leading, attributes: context.attributes, state: context.state,
                                             isStale: context.isStale)
                        .dynamicIsland(verticalPlacement: .belowIfTooWide)
                        .padding(.leading, Tokens.Space.xxs)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveActivityExpandedView(region: .trailing, attributes: context.attributes, state: context.state,
                                             art: hero, poster: poster, isStale: context.isStale)
                        .padding(.trailing, Tokens.Space.xxs)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityExpandedView(region: .bottom, attributes: context.attributes, state: context.state,
                                             isStale: context.isStale)
                        .padding(.horizontal, Tokens.Space.xxs)
                        .padding(.top, Tokens.Space.xxs)
                }
            } compactLeading: {
                LiveActivityCompactView(slot: .leading, attributes: context.attributes, state: context.state,
                                        poster: poster, isStale: context.isStale)
            } compactTrailing: {
                LiveActivityCompactView(slot: .trailing, attributes: context.attributes, state: context.state,
                                        isStale: context.isStale)
            } minimal: {
                LiveActivityMinimalView(attributes: context.attributes, state: context.state, poster: poster,
                                        isStale: context.isStale)
            }
            .keylineTint(LiveActivityInk.keyline)
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
            LiveActivitySmallView(attributes: context.attributes, state: context.state,
                                  poster: ActivityArt.poster(context.attributes), isStale: context.isStale)
                .padding(Tokens.Space.s)
        default:
            LiveActivityLockScreenView(attributes: context.attributes, state: context.state,
                                       art: ActivityArt.hero(context.attributes), isStale: context.isStale)
        }
    }
}

/// The show's art for the activity, drawn down small: a Live Activity may fail to draw a large image, and the views
/// show it at most about 160 × 140 pt (the banner's edge) or 50 pt (the island). Nil when the app hasn't saved any,
/// e.g. the Debug show; every view is designed to work without it.
private enum ActivityArt {
    static func hero(_ attributes: DropActivityAttributes) -> UIImage? {
        WidgetArtwork.image(showID: attributes.showID, maxPixel: 300)
    }

    static func poster(_ attributes: DropActivityAttributes) -> UIImage? {
        WidgetArtwork.poster(showID: attributes.showID, maxPixel: 96)
    }
}
