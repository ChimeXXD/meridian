import SwiftUI
import WidgetKit

/// The one Airstamp widget, in all six families (SPEC §5, UI-BRIEF §6.1): how long until the next episode, in the
/// viewer's time zone, and where it's on.
struct NextDropWidget: Widget {
    static let kind = "NextDrop"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: NextDropProvider()) { moment in
            NextDropWidgetView(moment: moment)
        }
        .configurationDisplayName("Next episode")
        .description("How long until your next episode, in your time zone, and where it's on.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular, .systemSmall, .systemMedium,
                            .systemLarge])
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
            MediumWidgetView(moment: moment, art: WidgetArtwork.images(for: moment.upNext, rowPixel: nil))
        case .systemLarge:
            LargeWidgetView(moment: moment, art: WidgetArtwork.images(
                for: moment.upNext, rowPixel: Int(MediumWidgetRow.thumbnail * 3)))
        default:
            // The small widget is 158 pt square, about 480 px at 3x.
            SmallWidgetView(moment: moment, art: moment.current.flatMap {
                WidgetArtwork.image(showID: $0.showID, maxPixel: 480)
            })
        }
    }
}
