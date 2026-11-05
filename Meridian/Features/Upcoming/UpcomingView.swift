import SwiftUI

/// Upcoming (SPEC §1, UI-BRIEF §5.2) in Night Sky (D-38): the next show's art fades into night with the countdown
/// and when it's out; everything else is one quiet list in SPEC's sections. Sections are recomputed from the clock
/// on every minute and at each drop's section change (`UpcomingSchedule`), so a drop moves to "Out now" and on without
/// a reload; only the countdowns redraw every second.
struct UpcomingView: View {
    /// Nil until the first load finishes.
    let result: UpcomingLoader.Result?
    let artwork: [String: ShowArtwork]
    let hasShows: Bool
    /// The last refresh that reached every show, for "Updated 14:05" when one fails (D6-2).
    var lastUpdated: Date? = nil
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil
    var onSelect: (Drop) -> Void = { _ in }
    /// A followed show with nothing scheduled: its own page, with its last episodes and Unfollow (UX audit #12).
    var onSelectQuiet: (QuietShow) -> Void = { _ in }
    var onFind: () -> Void = {}
    var onRefresh: () async -> Void = {}

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // The page follows the clock only where its sections or words change; each countdown ticks in its own
        // `TimelineView(.countdown)`, so the sort, the art and its palette aren't redone every second.
        TimelineView(UpcomingSchedule(changes: UpcomingSections.changes(drops: result?.drops ?? []))) { context in
            let sections = UpcomingSections.make(drops: result?.drops ?? [],
                                                 nothingScheduled: result?.nothingScheduled ?? [], now: context.date)
            ArtworkLoaderView(url: (sections.hero?.showID ?? sections.spotlightShowID).flatMap { artwork[$0]?.hero },
                              maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
                let base = (hero?.palette ?? .neutral).night.color
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        top(sections, image: hero?.image, base: base, now: context.date)
                        list(sections, now: context.date)
                        if let status = UpcomingStatus.line(failed: result?.failed ?? [], lastUpdated: lastUpdated,
                                                            now: context.date, formatter: formatter) {
                            Text(status)
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
                UpcomingHero(drop: hero, image: image, base: base, formatter: formatter)
            }
            .buttonStyle(.plain)
            // On the button: a button hides its label's own container, so the hero is found by this ID.
            .accessibilityIdentifier("upcoming-hero")
        } else if case .dateOnly(let drop) = sections.spotlight {
            // Tappable like the hero: the date-only show left its section, so this is the only way to its detail.
            Button { onSelect(drop) } label: { spotlight(sections, image: image, base: base, now: now) }
                .buttonStyle(.plain)
                .accessibilityIdentifier("upcoming-spotlight")
        } else if case .quiet(let show) = sections.spotlight {
            // A quiet show opens its own page, so it can be unfollowed from here too (UX audit #12).
            Button { onSelectQuiet(show) } label: { spotlight(sections, image: image, base: base, now: now) }
                .buttonStyle(.plain)
                .accessibilityIdentifier("upcoming-spotlight")
        } else {
            // Nothing to feature (every drop has gone, or every show failed to load): SPEC's sentence on its own.
            Text(sections.emptyHeadline(formatter: formatter, now: now))
                .serif(28, relativeTo: .title)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, Tokens.Space.l)
                .padding(.top, 120)
                .accessibilityIdentifier("upcoming-empty")
        }
    }

    /// No countdown yet: the show's art still leads, with its title and why there's no time (Chime: "too bland").
    /// SPEC's sentence stays, small, under it.
    private func spotlight(_ sections: UpcomingSections, image: UIImage?, base: Color, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NightArtHeader(image: image, base: base)
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                switch sections.spotlight {
                case .dateOnly(let drop):
                    Text(drop.showName)
                        .serif(32, relativeTo: .largeTitle)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("upcoming-spotlight-title")
                    // The title already names the show, so the line is the usual wording (D-40), not "Silo returns …".
                    Text(ReleaseWording.outLine(drop, now: now, formatter: formatter))
                        .font(.body.weight(.medium))
                        .accessibilityIdentifier("upcoming-spotlight-note")
                    ReleaseMeta(drop: drop, formatter: formatter)
                case .quiet(let show):
                    Text(show.name)
                        .serif(32, relativeTo: .largeTitle)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("upcoming-spotlight-title")
                    Text(ReleaseWording.quietNote(status: show.status, lastAired: show.lastAired, formatter: formatter,
                                                  now: now))
                        .font(.body.weight(.medium))
                        .accessibilityIdentifier("upcoming-spotlight-note")
                    Text(sections.emptyHeadline(formatter: formatter, now: now))
                        .font(.footnote)
                        .foregroundStyle(NightInk.muted)
                        .padding(.top, Tokens.Space.xs)
                        .accessibilityIdentifier("upcoming-empty")
                case nil:
                    EmptyView()
                }
            }
            .padding(.horizontal, Tokens.Space.l)
            .padding(.top, -64)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("upcoming-spotlight")
    }

    private var emptyFollow: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.m) {
            Text("Follow a show to see its countdown here")
                .serif(28, relativeTo: .title)
                .accessibilityIdentifier("upcoming-empty-follow")
            Button("Find a show", action: onFind)
                .buttonStyle(PrimaryButtonStyle())
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
                        if !section.shows.isEmpty { quietGrid(section.shows, now: now) }
                    }
                }
            }
        }
        .padding(.horizontal, Tokens.Space.l)
    }

    /// Followed shows with nothing scheduled, as the poster grid Chime picked for Search: poster, title, and why
    /// there's no time.
    private func quietGrid(_ shows: [UpcomingLoader.Quiet], now: Date) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.s, alignment: .top),
                                   count: dynamicTypeSize.isAccessibilitySize ? 2 : 3),
                  spacing: Tokens.Space.m) {
            ForEach(Array(shows.enumerated()), id: \.element.showID) { index, show in
                Button { onSelectQuiet(show) } label: {
                    VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                        PosterImage(url: artwork[show.showID]?.posterThumbnail ?? artwork[show.showID]?.poster, cornerRadius: 8)
                            .aspectRatio(2 / 3, contentMode: .fit)
                        Text(show.name)
                            .font(.footnote.weight(.medium))
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                            .accessibilityIdentifier("nothing-\(index + 1)-title")
                        Text(ReleaseWording.quietNote(status: show.status, lastAired: show.lastAired, formatter: formatter,
                                                      now: now))
                            .font(.caption)
                            .foregroundStyle(NightInk.muted)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                            .accessibilityIdentifier("nothing-\(index + 1)-note")
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("nothing-\(index + 1)")
            }
        }
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
                    // The countdown sits beside the title only, so the lines below get the full width. At the
                    // accessibility sizes it goes under the title instead of squeezing it (UX audit #8).
                    let largeText = dynamicTypeSize.isAccessibilitySize
                    let titleLine = largeText ? AnyLayout(VStackLayout(alignment: .leading, spacing: Tokens.Space.xxs))
                        : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
                    titleLine {
                        Text(drop.showName)
                            .serif(20, relativeTo: .title3)
                            .lineLimit(largeText ? nil : 2)
                            .accessibilityIdentifier("drop-row-\(index)-title")
                        if !largeText { Spacer(minLength: Tokens.Space.xs) }
                        if drop.confidence != .dateOnly {  // a date-only drop's day is already in the out line
                            TimelineView(.countdown) { context in
                                CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate,
                                              now: context.date, size: 24, tint: .white, formatter: formatter,
                                              alignment: largeText ? .leading : .trailing)
                                    .environment(\.numeralStudy, .night)
                                    // Stacked, it may shrink to the row's width (minimumScaleFactor) instead of
                                    // overflowing.
                                    .fixedSize(horizontal: !largeText, vertical: true)
                            }
                        }
                    }
                    Text(ReleaseWording.outLine(drop, now: now, formatter: formatter))
                        .font(.subheadline)
                        .foregroundStyle(NightInk.secondary)
                        .accessibilityIdentifier("drop-row-\(index)-time")
                    ReleaseMeta(drop: drop, formatter: formatter)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("drop-row-\(index)")
    }
}
