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

    enum Kind: String, CaseIterable { case tv = "TV", anime = "Anime" }

    @Environment(\.modelContext) private var context
    @Query(sort: \FollowedShow.followedAt) private var followed: [FollowedShow]
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var state = Phase.idle
    @State private var kind = Kind.tv
    /// Shows with episodes in the next few days, shown before you type: TV from `AiringSoon`, anime from AniList.
    @State private var airing: [Kind: [SearchResult]] = [:]
    private var airingSoon: [SearchResult] { airing[kind] ?? [] }

    private enum Phase: Equatable { case idle, searching, done, failed }

    private static let page = ArtworkPalette.neutral.night.color

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Picker("Kind", selection: $kind) {
                        ForEach(Kind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
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
            .searchable(text: $query, prompt: "Shows and anime")
            .onSubmit(of: .search) { Task { await search() } }
            .task(id: kind) {
                guard airingSoon.isEmpty else { return }
                switch kind {
                case .tv:
                    guard let shows = await AiringSoon.load(client: client) else { return }
                    airing[.tv] = shows.map(SearchResult.init(show:))
                case .anime:
                    guard let media = try? await anilist.airingSoon(from: .now, days: 7) else { return }
                    airing[.anime] = Array(media.prefix(AiringSoon.limit)).map(SearchResult.init(media:))
                }
            }
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
            if let debugQuery = DebugLaunch.query, query.isEmpty { query = debugQuery }
        }
        #endif
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .idle where airingSoon.isEmpty:
            message(kind == .tv ? "Search TVmaze for a show to follow" : "Search AniList for an anime to follow",
                    id: "search-empty")
        case .idle:
            airingGrid
        case .searching:
            ProgressView().frame(maxWidth: .infinity).padding(.top, Tokens.Space.xl)
        case .failed:
            message("Couldn't reach \(kind == .tv ? "TVmaze" : "AniList"). Check your connection and try again.",
                    id: "search-error")
        case .done where results.isEmpty:
            message("No shows match \u{201C}\(query)\u{201D}", id: "search-no-results")
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

    private func message(_ text: String, id: String) -> some View {
        Text(text)
            .foregroundStyle(NightInk.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Tokens.Space.l)
            .accessibilityIdentifier(id)
    }

    // MARK: Plex's poster grid, for both the airing shows and the results

    private var airingGrid: some View {
        posterGrid(kind == .tv ? "Airing in the next few days" : "Airing in Japan this week",
                   headerID: "search-airing-header", airingSoon, idPrefix: "airing") { result in
            if let network = result.network { Text(network) }
        }
    }

    /// One grid for both lists, so the airing shows and the results can't drift apart. Cells are `<idPrefix>-<n>`.
    private func posterGrid<Meta: View>(_ header: String, headerID: String, _ shows: [SearchResult], idPrefix: String,
                                        @ViewBuilder meta: @escaping (SearchResult) -> Meta) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            Text(header)
                .font(.system(size: 22, design: .serif))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(headerID)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.s, alignment: .top), count: 3),
                      spacing: Tokens.Space.m) {
                ForEach(Array(shows.enumerated()), id: \.element.id) { index, result in
                    posterCell(result, id: "\(idPrefix)-\(index + 1)", meta: meta(result))
                }
            }
        }
        .padding(.top, Tokens.Space.s)
    }

    private func posterCell(_ result: SearchResult, id: String, meta: some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            PosterImage(url: result.poster, cornerRadius: 8)
                .aspectRatio(2 / 3, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    followButton(result, size: 32, id: "\(id)-follow").padding(Tokens.Space.xxs)
                }
            Text(result.title)
                .font(.footnote.weight(.medium))
                .lineLimit(2)
                .accessibilityIdentifier("\(id)-title")
            // Two lines a part, so a long network ("Amazon Prime Video") can't push its country out of the cell.
            meta
                .font(.caption)
                .foregroundStyle(NightInk.muted)
                .lineLimit(2)
                .accessibilityIdentifier("\(id)-meta")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(id)
    }

    private func followButton(_ result: SearchResult, size: CGFloat, id: String) -> some View {
        let following = followed.contains { $0.key == FollowedShow.key(catalog: result.catalog, id: result.id) }
        return Button {
            let store = FollowStore(context: context)
            try? following ? store.unfollow(catalog: result.catalog, id: result.id) : store.follow(result.followShow)
        } label: {
            Image(systemName: following ? "checkmark" : "plus")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(following ? .black : .white)
                .frame(width: size, height: size)
                .background(following ? AnyShapeStyle(.white) : AnyShapeStyle(.black.opacity(0.55)), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(following ? 0 : 0.35)))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(following ? "Following \(result.title)" : "Follow \(result.title)")
        .accessibilityIdentifier(id)
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
        } catch {
            // Typing on cancels the debounced search; that isn't a connection failure.
            guard !Task.isCancelled, text == query.trimmingCharacters(in: .whitespaces) else { return }
            state = .failed
        }
    }
}
