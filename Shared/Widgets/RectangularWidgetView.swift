import SwiftUI
import WidgetKit

/// accessoryRectangular, after #Udemy: a glyph and when it's out on the top line, so how sure the time is ("Out Wed
/// 02:00", "Expected Mon 09:00") is read first; then the show name and the countdown with the provider beside it. The
/// provider keeps its country ("HBO · US") even with no official stream here; the VoiceOver phrase says so. A date-only
/// drop shows its day in the countdown's place and "Time not announced" on top.
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
                HStack(spacing: 3) {
                    Image(systemName: "tv").font(.system(size: 10, weight: .semibold))
                    Text(WidgetText.when(drop, now: moment.date, formatter: formatter))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.75)
                .accessibilityIdentifier("widget-rect-meta")
                Text(drop.showName)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .lineLimit(1)
                    .widgetAccentable()
                    .accessibilityIdentifier("widget-rect-title")
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate,
                                  now: moment.date, size: 26, formatter: formatter)
                        .environment(\.numeralStudy, .night)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityIdentifier("widget-rect-countdown")
                    if let provider = drop.provider?.display {
                        Text(provider)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .accessibilityIdentifier("widget-rect-provider")
                    }
                }
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
