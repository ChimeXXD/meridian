import SwiftUI
import WidgetKit

/// The one Airstamp widget, in all five families (SPEC §5, UI-BRIEF §6.1): how long until the next episode, in the
/// viewer's time zone, and where it's on.
struct NextDropWidget: Widget {
    static let kind = "NextDrop"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: NextDropProvider()) { moment in
            NextDropWidgetView(moment: moment)
        }
        .configurationDisplayName("Next episode")
        .description("How long until your next episode, in your time zone, and where it's on.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular, .systemSmall, .systemMedium])
    }
}

/// Picks the family's view and loads the small art the Home Screen families use.
struct NextDropWidgetView: View {
    let moment: WidgetMoment

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            InlineWidgetView(moment: moment)
        case .accessoryCircular:
            CircularWidgetView(moment: moment)
        case .accessoryRectangular:
            RectangularWidgetView(moment: moment)
        case .systemMedium:
            MediumWidgetView(moment: moment, art: WidgetArtwork.images(for: moment.upNext))
        default:
            SmallWidgetView(moment: moment, art: moment.current.flatMap { WidgetArtwork.image(showID: $0.showID) })
        }
    }
}
