import SwiftUI
import WidgetKit

/// systemSmall, after #Tripsy: the art keeps the top half clear, with only the provider tagged in its corner; the show
/// name, a big light serif countdown (bright number, dim unit, #117 one year) and when it's out in words (D-40: "Out
/// Wed at 02:00", "Expected Mon at 09:00") sit together bottom-left, where the art has faded into night (D-38). The
/// countdown is the one accentable element.
struct SmallWidgetView: View {
    let moment: WidgetMoment
    var art: UIImage?
    var formatter = DropFormatter()

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .environment(\.colorScheme, .dark)
            .containerBackground(for: .widget) { WidgetBackdrop(art: dimmed ? nil : art) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(WidgetAccessibility.label(for: moment.spokenDrop, now: moment.date, formatter: formatter))
    }

    @ViewBuilder private var content: some View {
        if let drop = moment.current {
            VStack(alignment: .leading, spacing: 0) {
                if let provider = drop.provider?.display {
                    WidgetTag(text: provider)
                        .accessibilityIdentifier("widget-small-provider")
                }
                Spacer(minLength: Tokens.Space.xxs)
                Text(drop.showName)
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.primary, when: dimmed))
                    .lineLimit(1).minimumScaleFactor(0.75)
                    .accessibilityIdentifier("widget-small-title")
                CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: moment.date,
                              size: 36, tint: WidgetInk.primary, formatter: formatter)
                    .environment(\.numeralStudy, .night)
                    .accessibilityIdentifier("widget-small-countdown")
                Text(WidgetText.outLine(drop, now: moment.date, formatter: formatter))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.secondary, when: dimmed))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .accessibilityIdentifier("widget-small-out")
            }
        } else {
            WidgetEmptyState(moment: moment, lineLimit: 3, formatter: formatter)
                .accessibilityIdentifier("widget-small-title")
        }
    }
}
