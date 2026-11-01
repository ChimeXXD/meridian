import SwiftUI
import WidgetKit

/// systemMedium, after #Apple TV: the next show leads. Its art fills the top and fades into night (D-38), the provider
/// is tagged in the corner, and its name, when it's out (in words, D-40) and its countdown sit where the art has faded.
/// The next two follow as one-line rows, each with its small poster; "+3 more this week" in the other corner counts
/// the rest. With nothing to count down it says what to do. Each show is its own VoiceOver element with the full
/// phrase.
struct MediumWidgetView: View {
    let moment: WidgetMoment
    /// The hero's wide art. Missing art is fine: the widget reads the same without it.
    var heroArt: UIImage?
    /// The rows' small posters by show ID.
    var posters: [String: UIImage] = [:]
    var formatter = DropFormatter()

    /// The hero and two rows.
    static let shown = 3

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        Group {
            if let hero = moment.upNext.first {
                VStack(alignment: .leading, spacing: 0) {
                    WidgetTagRow(provider: hero.provider?.display,
                                 more: WidgetText.more(moment.moreThisWeek(showing: Self.shown)))
                    Spacer(minLength: Tokens.Space.xxs)
                    heroRow(hero).accessibilityIdentifier("widget-medium-row-1")
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, drop in
                        WidgetCompactRow(drop: drop, now: moment.date, poster: posters[drop.showID],
                                         showsPoster: showsPosters, formatter: formatter)
                            .padding(.top, index == 0 ? Tokens.Space.xs : 3)
                            .accessibilityIdentifier("widget-medium-row-\(index + 2)")
                    }
                    ForEach(Array(quiet.enumerated()), id: \.element.showID) { index, show in
                        WidgetQuietRow(show: show, now: moment.date, poster: posters[show.showID],
                                       showsPoster: showsPosters, formatter: formatter)
                            .padding(.top, rows.isEmpty && index == 0 ? Tokens.Space.xs : 3)
                            .accessibilityIdentifier("widget-medium-row-\(rows.count + index + 2)")
                    }
                }
            } else if !moment.nothingScheduled.isEmpty {
                WidgetQuietList(moment: moment, posters: posters, shown: Self.shown, formatter: formatter)
                    .accessibilityIdentifier("widget-medium-empty")
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
        .containerBackground(for: .widget) { WidgetBackdrop(art: dimmed ? nil : heroArt) }
        .accessibilityElement(children: .contain)
    }

    private var rows: [Drop] { moment.rows(showing: Self.shown) }

    private var quiet: [QuietShow] { moment.quietRows(showing: Self.shown) }

    private var showsPosters: Bool {
        !dimmed && (rows.map(\.showID) + quiet.map(\.showID)).contains { posters[$0] != nil }
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
                          size: 32, tint: WidgetInk.primary, formatter: formatter, alignment: .trailing)
                .environment(\.numeralStudy, .night)
                .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetAccessibility.label(for: drop, now: moment.date, formatter: formatter))
    }
}
