import SwiftUI

/// Upcoming in the artwork-led direction (D-37): the nearest drop as a full-bleed hero, the page tinted from its
/// art, and every later drop as a slab tinted from its own poster. The view re-reads the clock every minute, so
/// "2d 4h" stays current and a drop flips to "Out now" on time; within 24 hours the timer ticks by itself.
struct UpcomingArtView: View {
    /// Sorted by time to drop.
    let drops: [Drop]
    let artwork: [String: ShowArtwork]
    var zoneLine = "Times in Lagos · WAT"
    var formatter = DropFormatter()
    /// Where the list starts; the design preview uses `.bottom` to show the rows.
    var scrollAnchor: UnitPoint? = nil
    var onSelect: (Drop) -> Void = { _ in }

    var body: some View {
        TimelineView(.everyMinute) { context in
            ArtworkLoaderView(url: drops.first.flatMap { artwork[$0.showID]?.hero },
                              maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
                let palette = hero?.palette ?? .neutral
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let next = drops.first {
                            Button { onSelect(next) } label: {
                                UpcomingHero(drop: next, image: hero?.image, palette: palette, now: context.date, formatter: formatter)
                            }
                            .buttonStyle(.plain)
                            .overlay(alignment: .topLeading) { zone }
                        }
                        rows(now: context.date)
                    }
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(scrollAnchor)
                .background(palette.base.color)
                .overlay(alignment: .top) { StatusBarScrim(color: palette.base.color) }
                .ignoresSafeArea(edges: .top)
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private func rows(now: Date) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            ForEach(Array(Self.sections(after: drops, now: now).enumerated()), id: \.offset) { _, group in
                Text(group.title)
                    .font(.title3.weight(.bold))
                    .padding(.top, Tokens.Space.m)
                    .accessibilityAddTraits(.isHeader)
                ForEach(group.drops) { drop in
                    Button { onSelect(drop) } label: {
                        ArtDropRow(drop: drop, artwork: artwork[drop.showID], index: (drops.firstIndex(of: drop) ?? 0) + 1,
                                   now: now, formatter: formatter)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Tokens.Space.m)
        .padding(.bottom, Tokens.Space.xl)
    }

    /// SPEC's sections for everything after the hero. A first cut for the design pass; `UpcomingViewModel` owns
    /// the tested boundaries on Day 3.
    static func sections(after drops: [Drop], now: Date) -> [(title: String, drops: [Drop])] {
        let later = drops.dropFirst()
        let buckets: [(String, (Drop) -> Bool)] = [
            ("Next 24 hours", { $0.confidence != .dateOnly && $0.date.timeIntervalSince(now) <= 86_400 }),
            ("This week", { $0.confidence != .dateOnly && $0.date.timeIntervalSince(now) > 86_400
                && $0.date.timeIntervalSince(now) <= 7 * 86_400 }),
            ("Later", { $0.confidence != .dateOnly && $0.date.timeIntervalSince(now) > 7 * 86_400 }),
            ("Date only", { $0.confidence == .dateOnly }),
        ]
        return buckets.compactMap { title, test in
            let matching = later.filter(test)
            return matching.isEmpty ? nil : (title, Array(matching))
        }
    }

    private var zone: some View {
        Text(zoneLine)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, Tokens.Space.s)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.leading, Tokens.Space.m)
            .padding(.top, 62)
            .accessibilityIdentifier("upcoming-zone")
    }
}
