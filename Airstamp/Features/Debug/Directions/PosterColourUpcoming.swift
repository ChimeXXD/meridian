#if DEBUG
import SwiftUI

/// Direction C, Poster Colour: every show owns a bold colour taken from its poster. Upcoming is Fixtured's schedule,
/// day stamps on the left and one colour card per show, with the poster tucked into the card (Peacock) and a serif
/// countdown from Insight Timer (picks: Fixtured, Paramount+, Plex, Peacock, Sunlitt).
struct PosterColourUpcoming: View {
    let drops: [Drop]
    let artwork: [String: ShowArtwork]
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil
    var onSelect: (Drop) -> Void = { _ in }

    static let page = Color(red: 0.965, green: 0.953, blue: 0.925)

    var body: some View {
        TimelineView(.everyMinute) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.l) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upcoming").font(.system(size: 38, weight: .bold, design: .serif))
                        Text("Times in Lagos · WAT")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("upcoming-zone")
                    }
                    ForEach(days(now: context.date), id: \.key) { day in
                        HStack(alignment: .top, spacing: Tokens.Space.s) {
                            stamp(top: day.top, number: day.number)
                            VStack(spacing: 10) {
                                ForEach(day.drops) { drop in
                                    let index = (drops.firstIndex(of: drop) ?? 0) + 1
                                    Button { onSelect(drop) } label: {
                                        PosterColourCard(drop: drop, artwork: artwork[drop.showID], index: index,
                                                         featured: index == 1, now: context.date, formatter: formatter)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Tokens.Space.m)
                .padding(.vertical, Tokens.Space.s)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(scrollAnchor)
            .background(Self.page)
        }
        .environment(\.colorScheme, .light)
    }

    /// Fixtured's day stamp: "TODAY" over the day of the month.
    private func stamp(top: String, number: String) -> some View {
        VStack(spacing: 2) {
            Text(top).font(.caption2.weight(.bold)).tracking(0.6).foregroundStyle(.secondary)
            Text(number).font(.system(size: 22, weight: .semibold, design: .serif))
        }
        .frame(width: 58)
        .padding(.top, Tokens.Space.xs)
        .accessibilityElement(children: .combine)
    }

    /// Drops grouped by local day; a date-only drop is grouped by its listed airdate (D-28).
    private func days(now: Date) -> [(key: String, top: String, number: String, drops: [Drop])] {
        var order: [String] = []
        var groups: [String: (top: String, number: String, drops: [Drop])] = [:]
        for drop in drops {
            let key: String, top: String
            if drop.confidence == .dateOnly, let airdate = drop.airdate {
                key = airdate
                top = (formatter.airdate(airdate) ?? airdate).split(separator: " ").first.map(String.init)?.uppercased() ?? ""
            } else {
                key = formatter.localDay(drop.date)
                top = String(formatter.relativeDay(drop.date, now: now).split(separator: " ").first ?? "").uppercased()
            }
            let number = String(Int(key.suffix(2)) ?? 0)
            if groups[key] == nil { order.append(key); groups[key] = (top, number, []) }
            groups[key]?.drops.append(drop)
        }
        return order.compactMap { key in groups[key].map { (key, $0.top, $0.number, $0.drops) } }
    }
}

/// One show as a colour card in its poster's colour, the poster tilted into the right edge.
struct PosterColourCard: View {
    let drop: Drop
    let artwork: ShowArtwork?
    let index: Int
    var featured = false
    let now: Date
    var formatter = DropFormatter()

    var body: some View {
        ArtworkLoaderView(url: artwork?.posterThumbnail ?? artwork?.poster, maxPixel: 420) { poster in
            let fill = (poster?.palette ?? .neutral).vivid
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24).fill(fill.color)
                ArtworkFill(image: poster?.image, palette: poster?.palette ?? .neutral)
                    .frame(width: featured ? 116 : 76, height: featured ? 172 : 112)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
                    .rotationEffect(.degrees(5))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, Tokens.Space.m)
                    .padding(.top, Tokens.Space.m)
                VStack(alignment: .leading, spacing: 6) {
                    Text([DirectionCopy.yourTime(drop, now: now, formatter: formatter), drop.provider?.display]
                        .compactMap(\.self).joined(separator: " · "))
                        .font(.footnote.weight(.bold))
                        .opacity(0.8)
                        .lineLimit(2)
                        .accessibilityIdentifier("drop-row-\(index)-time")
                    Text(drop.showName)
                        .font(.system(size: featured ? 28 : 21, weight: .semibold, design: .serif))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("drop-row-\(index)-title")
                    SourceChip(source: drop.source, confidence: drop.confidence)
                    Spacer(minLength: 0)
                    CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                                  size: featured ? 58 : 34, tint: fill.ink, formatter: formatter)
                        .environment(\.numeralStudy, .serif)
                }
                .padding(Tokens.Space.m)
                .padding(.trailing, featured ? 128 : 88)
            }
            .frame(minHeight: featured ? 250 : 176)
            .foregroundStyle(fill.ink)
            .environment(\.colorScheme, fill.prefersWhiteText ? .dark : .light)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("drop-row-\(index)")
    }
}
#endif
