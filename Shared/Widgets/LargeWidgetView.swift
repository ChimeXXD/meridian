import SwiftUI
import WidgetKit

/// systemLarge, after #Apple TV: the next show's art across the top fades into night (D-38), with the provider tagged
/// in its corner and "+3 more this week" in the other when shows don't fit; the show's name, a big serif countdown and
/// when it's out (in words, D-40) sit over the fade; the next three follow as rows with their small posters. With
/// nothing to count down it says what to do. Each show is its own VoiceOver element with the full phrase.
struct LargeWidgetView: View {
    let moment: WidgetMoment
    /// The hero's wide art. Missing art is fine: the widget reads the same without it.
    var heroArt: UIImage?
    /// The rows' small posters by show ID.
    var posters: [String: UIImage] = [:]
    var formatter = DropFormatter()

    /// How much of the height the hero's art covers.
    static let artCoverage: CGFloat = 0.62
    /// The hero and three rows.
    static let shown = 4

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        Group {
            if let hero = moment.upNext.first {
                VStack(alignment: .leading, spacing: 0) {
                    WidgetTagRow(provider: hero.provider?.display,
                                 more: WidgetText.more(moment.moreThisWeek(showing: Self.shown)))
                    Spacer(minLength: Tokens.Space.xxs)
                    heroBlock(hero).accessibilityIdentifier("widget-large-row-1")
                    VStack(spacing: Tokens.Space.xs) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, drop in
                            MediumWidgetRow(drop: drop, now: moment.date, art: posters[drop.showID],
                                            showsThumbnail: showsPosters, formatter: formatter)
                                .accessibilityIdentifier("widget-large-row-\(index + 2)")
                        }
                        ForEach(Array(quiet.enumerated()), id: \.element.showID) { index, show in
                            WidgetQuietRow(show: show, now: moment.date, poster: posters[show.showID],
                                           showsPoster: showsPosters, posterHeight: MediumWidgetRow.thumbnail,
                                           detailed: true, formatter: formatter)
                                .accessibilityIdentifier("widget-large-row-\(rows.count + index + 2)")
                        }
                    }
                    .padding(.top, Tokens.Space.s)
                }
            } else if !moment.nothingScheduled.isEmpty {
                WidgetQuietList(moment: moment, posters: posters, shown: Self.shown,
                                posterHeight: MediumWidgetRow.thumbnail, detailed: true, formatter: formatter)
                    .accessibilityIdentifier("widget-large-empty")
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
            WidgetBackdrop(art: dimmed ? nil : heroArt, coverage: Self.artCoverage)
        }
        .accessibilityElement(children: .contain)
    }

    private var rows: [Drop] { moment.rows(showing: Self.shown) }

    private var quiet: [QuietShow] { moment.quietRows(showing: Self.shown) }

    private var showsPosters: Bool {
        !dimmed && (rows.map(\.showID) + quiet.map(\.showID)).contains { posters[$0] != nil }
    }

    private func heroBlock(_ drop: Drop) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Two lines before it shortens: one cut a long name with room to spare (break-ui BU-11). The small
            // widget's title stays on one line (D-46).
            Text(drop.showName)
                .font(.system(size: 24, design: .serif))
                .foregroundStyle(WidgetInk.dimmed(WidgetInk.primary, when: dimmed))
                .lineLimit(2).minimumScaleFactor(0.75)
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: moment.date,
                          size: 46, tint: WidgetInk.primary, formatter: formatter, scalesWithText: false)
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
