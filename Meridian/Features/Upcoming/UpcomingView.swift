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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // The page follows the clock only where its sections or words change; each countdown ticks in its own
        // `TimelineView(.countdown)`, so the sort, the art and its palette aren't redone every second.
        TimelineView(UpcomingSchedule(changes: UpcomingSections.changes(drops: result?.drops ?? []))) { context in
            let sections = UpcomingSections.make(drops: result?.drops ?? [],
                                                 nothingScheduled: result?.nothingScheduled ?? [], now: context.date)
            let featured = sections.hero?.showID ?? sections.spotlightShowID
            // Known to have no art at all (its artwork loaded without a picture): the short header (EA-13). While the
            // artwork is still loading the header keeps its height.
            let hasArt = featured.flatMap { artwork[$0] }.map { $0.hero != nil } ?? true
            ArtworkLoaderView(url: featured.flatMap { artwork[$0]?.hero },
                              maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
                let base = (hero?.palette ?? .neutral).night.color
                ScrollView {
                    VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                        top(sections, image: hero?.image, base: base, hasArt: hasArt, now: context.date)
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
                    // Unfollowing, a refresh and the first load move the list into place instead of jumping (AD-6),
                    // keyed on which shows are shown, so the ticking countdowns never animate. Cut under Reduce Motion.
                    .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: Self.shownIDs(sections, loaded: result != nil))
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(scrollAnchor)
                .refreshable { await onRefresh() }
                .background(base)
                .statusBarShade(base, art: hasArtHeader(sections)
                                ? (hasArt ? NightArtHeader.defaultHeight : NightArtHeader.noArtHeight) : 0)
            }
        }
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func top(_ sections: UpcomingSections, image: UIImage?, base: Color, hasArt: Bool, now: Date) -> some View {
        if !hasShows {
            emptyFollow
        } else if result == nil {
            // The hero's layout in quiet bars, so the first countdown lands where they were (EA-6).
            UpcomingHeroPlaceholder(base: base)
        } else if let hero = sections.hero {
            Button { onSelect(hero) } label: {
                UpcomingHero(drop: hero, image: image, base: base, hasArt: hasArt, formatter: formatter)
            }
            .buttonStyle(.heroPress)
            // On the button: a button hides its label's own container, so the hero is found by this ID.
            .accessibilityIdentifier("upcoming-hero")
        } else if case .dateOnly(let drop) = sections.spotlight {
            // Tappable like the hero: the date-only show left its section, so this is the only way to its detail.
            Button { onSelect(drop) } label: { spotlight(sections, image: image, base: base, hasArt: hasArt, now: now) }
                .buttonStyle(.heroPress)
                .accessibilityIdentifier("upcoming-spotlight")
        } else if case .quiet(let show) = sections.spotlight {
            // A quiet show opens its own page, so it can be unfollowed from here too (UX audit #12).
            Button { onSelectQuiet(show) } label: {
                spotlight(sections, image: image, base: base, hasArt: hasArt, now: now)
            }
                .buttonStyle(.heroPress)
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
    private func spotlight(_ sections: UpcomingSections, image: UIImage?, base: Color, hasArt: Bool,
                           now: Date) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NightArtHeader(image: image, base: base, hasArt: hasArt)
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                switch sections.spotlight {
                case .dateOnly(let drop):
                    ShowTitle(name: drop.showName, testID: "upcoming-spotlight-title")
                    // The title already names the show, so the line is the usual wording (D-40), not "Silo returns …".
                    Text(ReleaseWording.outLine(drop, now: now, formatter: formatter))
                        .font(.body.weight(.medium))
                        .accessibilityIdentifier("upcoming-spotlight-note")
                    ReleaseMeta(drop: drop, formatter: formatter)
                case .quiet(let show):
                    ShowTitle(name: show.name, testID: "upcoming-spotlight-title")
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

    /// Whether the top of the page is a show's art (the hero or the spotlight), which the status-bar shade waits for.
    private func hasArtHeader(_ sections: UpcomingSections) -> Bool {
        hasShows && result != nil && (sections.hero != nil || sections.spotlight != nil)
    }

    /// The mark over the line, as on Welcome, and Welcome's wider rhythm (EA-14).
    private var emptyFollow: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            VStack(alignment: .leading, spacing: Tokens.Space.m) {
                MeridianMark()
                    .frame(width: 28 * MeridianMark.widthRatio, height: 28)
                    .accessibilityHidden(true)
                Text("Follow a show to see its countdown here")
                    .serif(28, relativeTo: .title)
                    .accessibilityIdentifier("upcoming-empty-follow")
            }
            Button("Find a show", action: onFind)
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("upcoming-empty-find")
        }
        .padding(.horizontal, Tokens.Space.l)
        .padding(.top, 120)
    }

    /// What the list's animation follows: the shows on the page, in order, and whether the first load is in.
    private static func shownIDs(_ sections: UpcomingSections, loaded: Bool) -> [String] {
        [loaded ? "loaded" : "loading"] + sections.sections.flatMap { $0.drops.map(\.id) + $0.shows.map(\.showID) }
    }

    private static let sectionIDs = ["Out now": "out-now", "Next 24 hours": "next-24", "This week": "this-week",
                                     "Later": "later", "Date only": "date-only", "Nothing scheduled": "nothing"]

    private func list(_ sections: UpcomingSections, now: Date) -> some View {
        let order = sections.sections.flatMap(\.drops).map(\.id)
        return VStack(alignment: .leading, spacing: Tokens.Space.xl) {
            ForEach(sections.sections, id: \.title) { section in
                // Rows 16 apart, 8 under their header and 32 between sections, so a section reads as one group (EA-7).
                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    Text(section.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NightInk.muted)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("section-header-\(Self.sectionIDs[section.title] ?? section.title)")
                    VStack(alignment: .leading, spacing: Tokens.Space.m) {
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
                .buttonStyle(.rowPress)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("nothing-\(index + 1)")
            }
        }
    }

    /// The show's poster, then the hero's facts in a smaller size: title with its countdown, when it's out, episode
    /// and provider. At the accessibility sizes the poster goes above the text, so the title has the row's full width
    /// and doesn't break mid-word (BU-6).
    private func row(_ drop: Drop, index: Int, now: Date) -> some View {
        let largeText = dynamicTypeSize.isAccessibilitySize
        let layout = largeText ? AnyLayout(VStackLayout(alignment: .leading, spacing: Tokens.Space.xs))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Tokens.Space.m))
        return Button { onSelect(drop) } label: {
            layout {
                // A 2:3 poster, as the widgets' rows show (D-47, EA-8): wide key art cropped to a square lost the
                // title. Top-aligned, 3 pt down so its top meets the title's capitals (EA-7).
                PosterImage(url: artwork[drop.showID]?.widgetPoster, cornerRadius: 8)
                    .frame(width: 44, height: 66)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // its no-poster glyph stays inside the 44 pt
                    .padding(.top, largeText ? 0 : 3)
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    // The countdown sits beside the title only, so the lines below get the full width. At the
                    // accessibility sizes it goes under the title instead of squeezing it (UX audit #8).
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
                                CountdownSlot(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate,
                                              now: context.date, size: 24, formatter: formatter,
                                              alignment: largeText ? .leading : .trailing)
                                    .environment(\.numeralStudy, .night)
                                    // Its full size at every text size: stacked, it has the row's width, and it was
                                    // shrinking to the smallest text in the row (BU-6). An app screen, not a widget,
                                    // so `fixedSize` on the timer is safe here (rule 4).
                                    .fixedSize()
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.rowPress)
        .accessibilityIdentifier("drop-row-\(index)")
    }
}
