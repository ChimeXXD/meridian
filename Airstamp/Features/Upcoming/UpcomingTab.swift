import SwiftData
import SwiftUI

/// The Upcoming tab: the followed shows from SwiftData, loaded through `UpcomingModel`, with Show detail pushed on
/// tap. Reloads when the followed list changes and each time the app becomes active (D-27).
struct UpcomingTab: View {
    let model: UpcomingModel
    var onFind: () -> Void = {}

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \FollowedShow.followedAt) private var followed: [FollowedShow]
    @State private var path: [Drop] = []

    var body: some View {
        NavigationStack(path: $path) {
            UpcomingView(result: model.result, artwork: model.artwork, hasShows: !followed.isEmpty,
                         onSelect: { path.append($0) }, onFind: onFind, onRefresh: { await model.refresh(followed) })
                .toolbarVisibility(.hidden, for: .navigationBar)
                .navigationDestination(for: Drop.self) { drop in
                    ShowDetailScreen(drop: drop, model: model, artwork: model.artwork[drop.showID])
                }
        }
        .task(id: followed.map(\.key)) { await model.refresh(followed) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.refresh(followed) } }
        }
    }
}

/// Show detail for a followed show: its Live Activity switch is stored on the show, and unfollow removes it.
struct ShowDetailScreen: View {
    let drop: Drop
    let model: UpcomingModel
    let artwork: ShowArtwork?

    @Environment(\.modelContext) private var context
    @Query private var shows: [FollowedShow]
    @State private var episodes: [PastEpisode] = []

    init(drop: Drop, model: UpcomingModel, artwork: ShowArtwork?) {
        self.drop = drop
        self.model = model
        self.artwork = artwork
        let key = FollowedShow.key(catalog: drop.showKey.catalog, id: drop.showKey.id)
        _shows = Query(filter: #Predicate<FollowedShow> { $0.key == key })
    }

    var body: some View {
        ShowDetailView(drop: drop, artwork: artwork, episodes: episodes, liveActivity: liveActivity,
                       onUnfollow: unfollow)
            .task { episodes = await model.pastEpisodes(showID: drop.showID) }
    }

    private var liveActivity: Binding<Bool> {
        Binding(get: { shows.first?.liveActivity ?? true },
                set: { value in
                    shows.first?.liveActivity = value
                    try? context.save()
                })
    }

    private func unfollow() {
        try? FollowStore(context: context).unfollow(catalog: drop.showKey.catalog, id: drop.showKey.id)
    }
}
