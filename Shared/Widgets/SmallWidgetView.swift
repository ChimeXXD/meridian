import SwiftUI
import WidgetKit

/// systemSmall: the show name small, a huge light serif countdown (bright number, dim unit, #117 one year), and when
/// it's out in words (D-40): "Out Wed at 02:00", "Expected Mon at 09:00". Night Sky like Upcoming's hero (D-38):
/// near-black, the art fading in from the top when there is some. The countdown is the one accentable element.
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
                Text(drop.showName)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.primary, when: dimmed))
                    .lineLimit(2).minimumScaleFactor(0.8)
                    .accessibilityIdentifier("widget-small-title")
                Spacer(minLength: Tokens.Space.xxs)
                CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: moment.date,
                              size: 42, tint: WidgetInk.primary, formatter: formatter)
                    .environment(\.numeralStudy, .night)
                    .accessibilityIdentifier("widget-small-countdown")
                Text(WidgetText.outLine(drop, now: moment.date, formatter: formatter))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.secondary, when: dimmed))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .padding(.top, 2)
                    .accessibilityIdentifier("widget-small-out")
                if let provider = drop.provider?.display {
                    Text(provider)
                        .font(.system(size: 11))
                        .foregroundStyle(WidgetInk.dimmed(WidgetInk.muted, when: dimmed))
                        .lineLimit(1)
                        .padding(.top, 1)
                        .accessibilityIdentifier("widget-small-provider")
                }
            }
        } else {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Spacer(minLength: 0)
                Text(WidgetText.emptyHeadline(moment, formatter: formatter))
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundStyle(WidgetInk.primary)
                    .lineLimit(3).minimumScaleFactor(0.8)
                    .widgetAccentable()
                    .accessibilityIdentifier("widget-small-title")
                Text(WidgetText.emptyDetail(moment))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.secondary, when: dimmed))
                    .lineLimit(2)
            }
        }
    }
}
