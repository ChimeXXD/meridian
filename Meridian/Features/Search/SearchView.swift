import SwiftData
import SwiftUI

/// Search (SPEC §1, UI-BRIEF §5.3), one poster grid from Chime's picks (Plex "Popular Searches"): three posters across,
/// the title and a muted meta line under each, and a round follow button on the poster's corner. Before you type it
/// holds shows airing in the next few days; once you search, the results, whose year · network · status tells
/// same-name shows apart. Nothing is followed until you tap its button. A TV | Anime switch (Hypelist's media switch)
/// picks TVmaze or AniList (D-19).
struct SearchView: View {
    let client: TVmazeClient
    let anilist: AniListClient
    let rules: RulesFile

    /// Service logos for the filter chips (D-44), read once from the bundle.
    private static let logos = NetworkLogos.bundled

    enum Kind: String, CaseIterable { case tv = "TV", anime = "Anime" }

    /// The show whose ✓ was tapped, waiting for "Stop following …?".
    @State private var unfollowing: SearchResult?
    /// Counts follow taps in the grid: the success tick follows a tap here, not a follow made on a pushed show page.
    @State private var followTaps = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.modelContext) private var context
    @Query(sort: \FollowedShow.followedAt) private var followed: [FollowedShow]
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var state = Phase.idle
    @State private var kind = Kind.tv
    /// Shows with episodes in the next few days, shown before you type: TV from `AiringSoon`, anime from AniList. The
    /// whole pool is kept; the filter and the 15-show cap apply when it's shown (D-43).
    @State private var airing: [Kind: [AiringItem]] = [:]
    /// The filter picked for each catalog this session; Popular until one is picked.
    @State private var filters: [Kind: SearchFilter] = [:]
    private var airingSoon: [AiringItem] { airing[kind] ?? [] }
    /// This week's shows per catalog: loading, failed, or loaded (UX audit #16: all three showed the same line).
    @State private var airingPhase: [Kind: Phase] = [:]
    /// Bumped by "Try again", so the airing task runs again.
    @State private var airingAttempt = 0
    private var filter: Binding<SearchFilter> {
        Binding { filters[kind] ?? .popular } set: { filters[kind] = $0 }
    }

    private enum Phase: Equatable { case idle, searching, done, failed }

    private static let page = ArtworkPalette.neutral.night.color

    /// The show pages opened from posters (any poster on the tab, results or the airing grid).
    @State private var path: [ShowRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Picker("Kind", selection: $kind) {
                        ForEach(Kind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .sensoryFeedback(.selection, trigger: kind)
                    .sensoryFeedback(.success, trigger: followTaps)  // once for the whole grid, not per button
                    .accessibilityIdentifier("search-kind")
                    content
                }
                    .padding(.horizontal, Tokens.Space.m)
                    .padding(.bottom, Tokens.Space.xl)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background(Self.page)
            .navigationTitle("Search")
            .navigationDestination(for: ShowRoute.self) { route in
                ShowPreviewView(route: route, client: client, anilist: anilist, rules: rules)
            }
            .unfollowConfirmation($unfollowing, title: \.title) { show in
                try? FollowStore(context: context).unfollow(catalog: show.catalog, id: show.id)
            }
            // Always shown, not hidden until a pull down (EA-5): Search is the field.
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Shows and anime")
            .onSubmit(of: .search) { Task { await search() } }
            .task(id: "\(kind.rawValue)|\(airingAttempt)") { await loadAiring() }
            .onChange(of: kind) {
                // The other catalog's results must not show (or be followed) while the new search waits.
                results = []
                state = .idle
            }
            .task(id: "\(kind.rawValue)|\(query)") {
                // Debounced: search after a short pause in typing, not on every key.
                guard query.count >= 2 else { results = []; state = .idle; return }
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                await search()
            }
        }
        .environment(\.colorScheme, .dark)
        #if DEBUG
        .onAppear {
            if DebugLaunch.anime { kind = .anime }
            if let debugFilter = DebugLaunch.filter { filters[kind] = debugFilter }
            if let debugQuery = DebugLaunch.query, query.isEmpty { query = debugQuery }
        }
        #endif
    }

    @ViewBuilder private var content: some View {
        switch state {
        // Nil until the first load starts, which is a load too: no "Search TVmaze…" flash before the spinner.
        case .idle where airingSoon.isEmpty && (airingPhase[kind] ?? .searching) == .searching:
            ProgressView("Finding this week's shows")
                .frame(maxWidth: .infinity).padding(.top, Tokens.Space.xl)
                .accessibilityIdentifier("search-airing-loading")
        case .idle where airingSoon.isEmpty && airingPhase[kind] == .failed:
            message("Couldn't load this week's shows. You can still search above.", id: "search-airing-error",
                    action: ("Try again", { airingAttempt += 1 }))
        case .idle where airingSoon.isEmpty:
            message(kind == .tv ? "Search TVmaze for a show to follow" : "Search AniList for an anime to follow",
                    id: "search-empty")
        case .idle:
            SearchFilterRow(options: AiringFilter.options(for: kind),
                            selection: filter, logos: Self.logos)
                .padding(.top, Tokens.Space.s)
            airingGrid
        case .searching:
            ProgressView().frame(maxWidth: .infinity).padding(.top, Tokens.Space.xl)
        case .failed:
            message("Couldn't reach \(kind == .tv ? "TVmaze" : "AniList"). Check your connection and try again.",
                    id: "search-error", action: ("Try again", { Task { await search() } }))
        case .done where results.isEmpty:
            // The other catalog may have it: an anime searched under TV, or the reverse.
            message("No shows match \u{201C}\(query)\u{201D}", id: "search-no-results",
                    action: (kind == .tv ? "Search anime instead" : "Search TV instead",
                             { kind = kind == .tv ? .anime : .tv }))
        case .done:
            posterGrid("Results", headerID: "search-results-header", results, idPrefix: "search-result") { result in
                // The year, network, country and status tell same-name shows apart.
                VStack(alignment: .leading, spacing: 0) {
                    if !result.gridMeta.isEmpty { Text(result.gridMeta) }
                    if let status = result.status { Text(status) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(result.meta)
            }
        }
    }

    /// A quiet line, with a way forward when there is one ("Try again", "Search anime instead").
    private func message(_ text: String, id: String, action: (title: String, run: () -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            Text(text)
                .foregroundStyle(NightInk.muted)
                .accessibilityIdentifier(id)
            if let action {
                outlinedButton(action.title, id: "\(id)-action", action: action.run)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Tokens.Space.l)
    }

    /// A way forward in the chips' outlined capsule, not the system's grey `.bordered` (EA-15).
    private func outlinedButton(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(.medium)).modifier(ChipCapsule(picked: false))
        }
        .buttonStyle(.controlPress)
        .accessibilityIdentifier(id)
    }

    /// This week's shows for the picked catalog, once; a failure says so and offers "Try again".
    private func loadAiring() async {
        guard airingSoon.isEmpty else { return }
        let loading = kind
        airingPhase[loading] = .searching
        switch loading {
        case .tv:
            guard let picks = await AiringSoon.load(client: client, rules: rules) else {
                // A switch of catalog cancels this load; that's not a failure, and the next visit loads again.
                if !Task.isCancelled { airingPhase[loading] = .failed }; return
            }
            airing[.tv] = picks.map(AiringItem.init(pick:))
        case .anime:
            guard let media = try? await anilist.airingSoon(from: .now, days: 7) else {
                if !Task.isCancelled { airingPhase[loading] = .failed }; return
            }
            airing[.anime] = media.compactMap { AiringItem(media: $0) }
        }
        airingPhase[loading] = .done
    }

    // MARK: Plex's poster grid, for both the airing shows and the results

    /// The airing grid under the picked filter. Each cell says where and when ("Netflix", "Expected Mon at 09:00"),
    /// so Today and Exact time show why a show is there (rule 3). Re-read every minute, so an episode that comes out
    /// while the grid is open leaves it and the "when" lines stay true.
    private var airingGrid: some View {
        TimelineView(.everyMinute) { context in
            airingGrid(now: context.date)
        }
    }

    @ViewBuilder private func airingGrid(now: Date) -> some View {
        let formatter = DropFormatter()
        let shown = AiringFilter.apply(filter.wrappedValue, to: airingSoon, now: now, formatter: formatter)
        let lines = Dictionary(shown.map { ($0.id, $0.releaseLine(now: now, formatter: formatter)) },
                               uniquingKeysWith: { first, _ in first })
        Group {
            if shown.isEmpty {
                VStack(alignment: .leading, spacing: Tokens.Space.s) {
                    message(AiringFilter.noMatch(filter.wrappedValue, kind: kind), id: "search-filter-empty")
                    if filter.wrappedValue != .popular {
                        outlinedButton("Show popular", id: "search-filter-clear") {
                            withAnimation(.snappy(duration: 0.2)) { filter.wrappedValue = .popular }
                        }
                    }
                }
            } else {
                posterGrid(kind == .tv ? "Airing in the next few days" : "Airing in Japan this week",
                           headerID: "search-airing-header", shown.map(\.result), idPrefix: "airing",
                           drops: Dictionary(shown.map { ($0.id, $0.drop) }, uniquingKeysWith: { first, _ in first })) { result in
                    VStack(alignment: .leading, spacing: 0) {
                        if let network = result.network { Text(network) }
                        // "Out tomorrow at 02:00" keeps "at" with its time when the cell wraps it (EA-12).
                        if let line = lines[result.id] {
                            Text(line.replacingOccurrences(of: " at ", with: " at\u{00A0}"))
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        // A new filter crossfades the grid instead of swapping it in place (AD-11); the chip's tap animates it.
        .id(filter.wrappedValue)
        .transition(.opacity)
    }

    /// One grid for both lists, so the airing shows and the results can't drift apart. Cells are `<idPrefix>-<n>`.
    /// `drops`: next episodes the grid already knows (the airing grid), so their page needn't ask again.
    private func posterGrid<Meta: View>(_ header: String, headerID: String, _ shows: [SearchResult], idPrefix: String,
                                        drops: [Int: Drop] = [:],
                                        @ViewBuilder meta: @escaping (SearchResult) -> Meta) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            // The section-header style Upcoming and Show detail use (UX audit #18): one role, one look.
            Text(header)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NightInk.muted)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(headerID)
            // One poster a row at the accessibility sizes, so titles and their certainty words aren't cut (audit #24).
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.s, alignment: .top),
                                     count: dynamicTypeSize.isAccessibilitySize ? 1 : 3),
                      spacing: Tokens.Space.m) {
                ForEach(Array(shows.enumerated()), id: \.element.id) { index, result in
                    posterCell(result, id: "\(idPrefix)-\(index + 1)", meta: meta(result),
                               route: ShowRoute(result: result, knownDrop: drops[result.id]))
                }
            }
        }
        .padding(.top, Tokens.Space.s)
    }

    private func posterCell(_ result: SearchResult, id: String, meta: some View, route: ShowRoute) -> some View {
        let following = followed.contains { $0.key == FollowedShow.key(catalog: result.catalog, id: result.id) }
        return SearchPosterCell(result: result, id: id, meta: meta, following: following,
                                onOpen: { path.append(route) }) {
            // Following is one tap; unfollowing asks first, as everywhere (UX audit #15).
            if following {
                unfollowing = result
            } else {
                // A tap you feel on follow, only once the show is really saved.
                if (try? FollowStore(context: context).follow(result.followShow)) != nil { followTaps += 1 }
            }
        }
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else { return }
        state = .searching
        do {
            let searched = kind
            let found = searched == .tv
                ? try await client.search(text).map(SearchResult.init(show:))
                : try await anilist.search(text).map(SearchResult.init(media:))
            guard searched == kind else { return }
            // A search for text the field no longer holds is stale; the newer one owns the list.
            guard text == query.trimmingCharacters(in: .whitespaces) else { return }
            results = found
            state = .done
            #if DEBUG
            if DebugLaunch.openFirstResult, path.isEmpty, let first = found.first {
                path.append(ShowRoute(result: first, knownDrop: nil))
            }
            #endif
        } catch {
            // Typing on cancels the debounced search; that isn't a connection failure.
            guard !Task.isCancelled, text == query.trimmingCharacters(in: .whitespaces) else { return }
            state = .failed
        }
    }
}
