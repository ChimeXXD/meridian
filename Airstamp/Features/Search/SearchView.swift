import SwiftData
import SwiftUI

/// Search (SPEC §1, UI-BRIEF §5.3): find a show on TVmaze and follow it. Every result shows year, network and status,
/// and nothing is followed until you tap its button. Anime search (AniList) joins with the AniList client.
struct SearchView: View {
    let client: TVmazeClient

    @Environment(\.modelContext) private var context
    @Query(sort: \FollowedShow.followedAt) private var followed: [FollowedShow]
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var state = Phase.idle

    private enum Phase: Equatable { case idle, searching, done, failed }

    var body: some View {
        NavigationStack {
            List {
                switch state {
                case .idle:
                    Text("Search TVmaze for a show to follow")
                        .foregroundStyle(NightInk.muted)
                        .accessibilityIdentifier("search-empty")
                case .searching:
                    ProgressView()
                case .failed:
                    Text("Couldn't reach TVmaze. Check your connection and try again.")
                        .foregroundStyle(NightInk.muted)
                        .accessibilityIdentifier("search-error")
                case .done where results.isEmpty:
                    Text("No shows match \u{201C}\(query)\u{201D}")
                        .foregroundStyle(NightInk.muted)
                        .accessibilityIdentifier("search-no-results")
                case .done:
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        row(result, index: index + 1)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.08))
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search")
            .onSubmit(of: .search) { Task { await search() } }
            .task(id: query) {
                // Debounced: search after a short pause in typing, not on every key.
                guard query.count >= 2 else { results = []; state = .idle; return }
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                await search()
            }
        }
        .environment(\.colorScheme, .dark)
        #if DEBUG
        .onAppear { if let debugQuery = DebugLaunch.query, query.isEmpty { query = debugQuery } }
        #endif
    }

    private func row(_ result: SearchResult, index: Int) -> some View {
        let following = followed.contains { $0.key == FollowedShow.key(catalog: result.catalog, id: result.id) }
        return HStack(spacing: Tokens.Space.m) {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text(result.title)
                    .font(.system(size: 20, design: .serif))
                    .accessibilityIdentifier("search-result-\(index)-title")
                Text(result.meta)
                    .font(.footnote)
                    .foregroundStyle(NightInk.muted)
                    .accessibilityIdentifier("search-result-\(index)-meta")
            }
            Spacer()
            Button {
                let store = FollowStore(context: context)
                try? following ? store.unfollow(catalog: result.catalog, id: result.id) : store.follow(result.followShow)
            } label: {
                Image(systemName: following ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(following ? "Following \(result.title)" : "Follow \(result.title)")
            .accessibilityIdentifier("search-result-\(index)-follow")
        }
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("search-result-\(index)")
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else { return }
        state = .searching
        do {
            let found = try await client.search(text).map(SearchResult.init(show:))
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
