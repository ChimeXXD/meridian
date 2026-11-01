import SwiftUI
import WidgetKit

/// systemLarge, after #Apple TV: the next show's art across the top fades into night (D-38), with the provider tagged
/// in its corner; the show's name, a big serif countdown and when it's out (in words, D-40) sit over the fade; the next
/// two follow as rows with small posters. With nothing to count down it says what to do. Each show is its own
/// VoiceOver element with the full phrase.
struct LargeWidgetView: View {
    let moment: WidgetMoment
    /// Small art by show ID. Missing entries are fine: the widget reads the same without it.
    var art: [String: UIImage] = [:]
    var formatter = DropFormatter()

    /// How much of the height the hero's art covers.
    static let artCoverage: CGFloat = 0.62

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        Group {
            if let hero = moment.upNext.first {
                VStack(alignment: .leading, spacing: 0) {
                    if let provider = hero.provider?.display {
                        WidgetProviderTag(text: provider).accessibilityHidden(true)
                    }
                    Spacer(minLength: Tokens.Space.xxs)
                    heroBlock(hero).accessibilityIdentifier("widget-large-row-1")
                    VStack(spacing: Tokens.Space.xs) {
                        ForEach(Array(moment.upNext.dropFirst().enumerated()), id: \.element.id) { index, drop in
                            MediumWidgetRow(drop: drop, now: moment.date, art: art[drop.showID],
                                            showsThumbnail: showsThumbnails, formatter: formatter)
                                .accessibilityIdentifier("widget-large-row-\(index + 2)")
                        }
                    }
                    .padding(.top, Tokens.Space.m)
                }
            } else {
                WidgetEmptyState(moment: moment, lineLimit: 3, formatter: formatter)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(WidgetAccessibility.label(for: moment.spokenDrop, now: moment.date,
                                                                  formatter: formatter))
                    .accessibilityIdentifier("widget-large-empty")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.colorScheme, .dark)
        .containerBackground(for: .widget) {
            WidgetBackdrop(art: dimmed ? nil : moment.upNext.first.flatMap { art[$0.showID] },
                           coverage: Self.artCoverage)
        }
        .accessibilityElement(children: .contain)
    }

    private var showsThumbnails: Bool {
        !dimmed && moment.upNext.dropFirst().contains { art[$0.showID] != nil }
    }

    private func heroBlock(_ drop: Drop) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(drop.showName)
                .font(.system(size: 24, design: .serif))
                .foregroundStyle(WidgetInk.dimmed(WidgetInk.primary, when: dimmed))
                .lineLimit(1).minimumScaleFactor(0.75)
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: moment.date,
                          size: 52, tint: WidgetInk.primary, formatter: formatter)
                .environment(\.numeralStudy, .night)
            Text(WidgetText.outLine(drop, now: moment.date, formatter: formatter))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(WidgetInk.dimmed(WidgetInk.secondary, when: dimmed))
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetAccessibility.label(for: drop, now: moment.date, formatter: formatter))
    }
}
