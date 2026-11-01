import SwiftUI
import WidgetKit

/// systemMedium, after #Apple TV: the next show leads. Its art fills the top and fades into night (D-38), the provider
/// is tagged in the corner, and its name, when it's out (in words, D-40) and its countdown sit where the art has faded.
/// The next two follow as one-line rows. With nothing to count down it says what to do. Each show is its own
/// VoiceOver element with the full phrase.
struct MediumWidgetView: View {
    let moment: WidgetMoment
    /// Small art by show ID. Missing entries are fine: the widget reads the same without it.
    var art: [String: UIImage] = [:]
    var formatter = DropFormatter()

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        Group {
            if let hero = moment.upNext.first {
                VStack(alignment: .leading, spacing: 0) {
                    if let provider = hero.provider?.display {
                        WidgetProviderTag(text: provider).accessibilityHidden(true)
                    }
                    Spacer(minLength: Tokens.Space.xxs)
                    heroRow(hero).accessibilityIdentifier("widget-medium-row-1")
                    ForEach(Array(moment.upNext.dropFirst().enumerated()), id: \.element.id) { index, drop in
                        WidgetCompactRow(drop: drop, now: moment.date, formatter: formatter)
                            .padding(.top, index == 0 ? Tokens.Space.xs : 2)
                            .accessibilityIdentifier("widget-medium-row-\(index + 2)")
                    }
                }
            } else {
                WidgetEmptyState(moment: moment, formatter: formatter)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(WidgetAccessibility.label(for: moment.spokenDrop, now: moment.date,
                                                                  formatter: formatter))
                    .accessibilityIdentifier("widget-medium-empty")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.colorScheme, .dark)
        .containerBackground(for: .widget) {
            WidgetBackdrop(art: dimmed ? nil : moment.upNext.first.flatMap { art[$0.showID] })
        }
        .accessibilityElement(children: .contain)
    }

    private func heroRow(_ drop: Drop) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: Tokens.Space.s) {
            VStack(alignment: .leading, spacing: 1) {
                Text(drop.showName)
                    .font(.system(size: 19, design: .serif))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.primary, when: dimmed))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(WidgetText.outLine(drop, now: moment.date, formatter: formatter))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.secondary, when: dimmed))
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .layoutPriority(1)
            Spacer(minLength: Tokens.Space.xs)
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: moment.date,
                          size: 32, tint: WidgetInk.primary, formatter: formatter)
                .environment(\.numeralStudy, .night)
                .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetAccessibility.label(for: drop, now: moment.date, formatter: formatter))
    }
}
