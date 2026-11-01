import SwiftUI
import WidgetKit

/// accessoryRectangular: the show name, the countdown, and "Out Wed 02:00 · Apple TV" on one dot-separated line
/// (SPEC §5, #128 Apple Sports). The provider keeps its country ("HBO · US") even with no official stream here; the
/// VoiceOver phrase says so. A date-only drop shows its day in the countdown's place and "Time not announced".
struct RectangularWidgetView: View {
    let moment: WidgetMoment
    var formatter = DropFormatter()

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Color.clear }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(WidgetAccessibility.label(for: moment.spokenDrop, now: moment.date, formatter: formatter))
    }

    @ViewBuilder private var content: some View {
        if let drop = moment.current {
            VStack(alignment: .leading, spacing: 0) {
                Text(drop.showName)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .lineLimit(1)
                    .accessibilityIdentifier("widget-rect-title")
                CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: moment.date,
                              size: 28, formatter: formatter)
                    .environment(\.numeralStudy, .night)
                    .accessibilityIdentifier("widget-rect-countdown")
                Text(WidgetText.meta(drop, now: moment.date, formatter: formatter))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1).minimumScaleFactor(0.75)
                    .accessibilityIdentifier("widget-rect-meta")
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(WidgetText.emptyHeadline(moment, formatter: formatter))
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .lineLimit(2).minimumScaleFactor(0.8)
                    .widgetAccentable()
                    .accessibilityIdentifier("widget-rect-title")
                Text(WidgetText.emptyDetail(moment))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .accessibilityIdentifier("widget-rect-meta")
            }
        }
    }
}
