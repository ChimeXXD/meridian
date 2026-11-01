import SwiftUI
import WidgetKit

/// systemMedium: the next 3 drops as rows under "Up next" (SPEC §5, #119 Speak), on the night base. With 1 or 2 drops
/// the rows sit at the top; with none it says what to do. Each row is its own VoiceOver element with the full phrase.
struct MediumWidgetView: View {
    let moment: WidgetMoment
    /// Small art by show ID. Missing entries are fine: the rows read the same without it.
    var art: [String: UIImage] = [:]
    var formatter = DropFormatter()

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Text("Up next")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WidgetInk.dimmed(WidgetInk.muted, when: dimmed))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("widget-medium-header")
            if moment.upNext.isEmpty {
                empty
            } else {
                ForEach(Array(moment.upNext.enumerated()), id: \.element.id) { index, drop in
                    MediumWidgetRow(drop: drop, now: moment.date, art: art[drop.showID], showsThumbnail: showsThumbnails,
                                    formatter: formatter)
                        .accessibilityIdentifier("widget-medium-row-\(index + 1)")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.colorScheme, .dark)
        .containerBackground(for: .widget) { WidgetInk.base }
        .accessibilityElement(children: .contain)
    }

    private var showsThumbnails: Bool {
        !dimmed && moment.upNext.contains { art[$0.showID] != nil }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Text(WidgetText.emptyHeadline(moment, formatter: formatter))
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundStyle(WidgetInk.primary)
                .lineLimit(2).minimumScaleFactor(0.8)
                .widgetAccentable()
            Text(WidgetText.emptyDetail(moment))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WidgetInk.dimmed(WidgetInk.secondary, when: dimmed))
        }
        .padding(.top, Tokens.Space.xxs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetAccessibility.label(for: moment.spokenDrop, now: moment.date, formatter: formatter))
        .accessibilityIdentifier("widget-medium-empty")
    }
}
