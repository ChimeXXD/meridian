import SwiftUI

/// Upcoming (SPEC §1, UI-BRIEF §5.2) in Night Sky (D-38): the next show's art fades into night with the countdown
/// and when it's out; everything else is one quiet list in SPEC's sections. Sections are recomputed from the clock
/// every minute, so a drop moves to "Out now" and on without a reload.
struct UpcomingView: View {
    /// Nil until the first load finishes.
    let result: UpcomingLoader.Result?
    let artwork: [String: ShowArtwork]
    let hasShows: Bool
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil
    var onSelect: (Drop) -> Void = { _ in }
    var onFind: () -> Void = {}
    var onRefresh: () async -> Void = {}

    var body: some View {
        TimelineView(.everyMinute) { context in
            let sections = UpcomingSections.make(drops: result?.drops ?? [],
                                                 nothingScheduled: result?.nothingScheduled ?? [], now: context.date)
            ArtworkLoaderView(url: sections.hero.flatMap { artwork[$0.showID]?.hero },
                              maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
                let base = (hero?.palette ?? .neutral).night.color
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        top(sections, image: hero?.image, base: base, now: context.date)
                        list(sections, now: context.date)
                        if let failed = result?.failed, !failed.isEmpty {
                            Text("Couldn't reach TVmaze for \(ListFormatter.localizedString(byJoining: failed)). Pull down to try again.")
                                .font(.footnote)
                                .foregroundStyle(NightInk.muted)
                                .padding(.horizontal, Tokens.Space.l)
                                .accessibilityIdentifier("upcoming-failed")
                        }
                    }
                    .padding(.bottom, Tokens.Space.xl)
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(scrollAnchor)
                .refreshable { await onRefresh() }
                .background(base)
                .overlay(alignment: .top) { StatusBarScrim(color: base) }
                .ignoresSafeArea(edges: .top)
            }
        }
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func top(_ sections: UpcomingSections, image: UIImage?, base: Color, now: Date) -> some View {
        if !hasShows {
            emptyFollow
        } else if result == nil {
            ProgressView().frame(maxWidth: .infinity).padding(.top, 240)
        } else if let hero = sections.hero {
            Button { onSelect(hero) } label: {
                UpcomingHero(drop: hero, image: image, base: base, now: now, formatter: formatter)
            }
            .buttonStyle(.plain)
        } else {
            Text(sections.emptyHeadline(formatter: formatter, now: now))
                .font(.system(size: 28, design: .serif))
                .padding(.horizontal, Tokens.Space.l)
                .padding(.top, 120)
                .accessibilityIdentifier("upcoming-empty")
        }
    }

    private var emptyFollow: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.m) {
            Text("Follow a show to see its countdown here")
                .font(.system(size: 28, design: .serif))
                .accessibilityIdentifier("upcoming-empty-follow")
            Button("Find a show", action: onFind)
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .accessibilityIdentifier("upcoming-empty-find")
        }
        .padding(.horizontal, Tokens.Space.l)
        .padding(.top, 120)
    }

    private static let sectionIDs = ["Out now": "out-now", "Next 24 hours": "next-24", "This week": "this-week",
                                     "Later": "later", "Date only": "date-only", "Nothing scheduled": "nothing"]

    private func list(_ sections: UpcomingSections, now: Date) -> some View {
        let order = sections.sections.flatMap(\.drops).map(\.id)
        return VStack(alignment: .leading, spacing: Tokens.Space.xl) {
            ForEach(sections.sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: Tokens.Space.s) {
                    Text(section.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NightInk.muted)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("section-header-\(Self.sectionIDs[section.title] ?? section.title)")
                    VStack(alignment: .leading, spacing: Tokens.Space.l) {
                        ForEach(section.drops) { drop in
                            row(drop, index: (order.firstIndex(of: drop.id) ?? 0) + 1, now: now)
                        }
                        ForEach(section.shows, id: \.self) { name in
                            Text(name)
                                .font(.system(size: 20, design: .serif))
                                .accessibilityIdentifier("nothing-row-\(name)")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Tokens.Space.l)
    }

    /// Art, then the hero's facts in a smaller size: title with its countdown, when it's out, episode and provider.
    private func row(_ drop: Drop, index: Int, now: Date) -> some View {
        Button { onSelect(drop) } label: {
            HStack(spacing: Tokens.Space.m) {
                ArtworkLoaderView(url: artwork[drop.showID]?.hero, maxPixel: 300) { loaded in
                    ArtworkFill(image: loaded?.image, palette: .neutral)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    // The countdown sits beside the title only, so the lines below get the full width.
                    HStack(alignment: .firstTextBaseline) {
                        Text(drop.showName)
                            .font(.system(size: 20, design: .serif))
                            .lineLimit(2)
                            .accessibilityIdentifier("drop-row-\(index)-title")
                        Spacer(minLength: Tokens.Space.xs)
                        if drop.confidence != .dateOnly {  // a date-only drop's day is already in the out line
                            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                                          size: 24, tint: .white, formatter: formatter)
                                .environment(\.numeralStudy, .night)
                                .fixedSize()
                        }
                    }
                    Text(ReleaseWording.outLine(drop, now: now, formatter: formatter))
                        .font(.subheadline)
                        .foregroundStyle(NightInk.secondary)
                        .accessibilityIdentifier("drop-row-\(index)-time")
                    ReleaseMeta(drop: drop)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("drop-row-\(index)")
    }
}
