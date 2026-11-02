import SwiftData
import SwiftUI
import UIKit

/// The Upcoming tab: the followed shows from SwiftData, loaded through `UpcomingModel`, with Show detail pushed on
/// tap. `RootView` reloads it when the followed list changes and each time the app becomes active (D-27); here it
/// reloads on pull-to-refresh.
struct UpcomingTab: View {
    let model: UpcomingModel
    var onFind: () -> Void = {}

    @Query(sort: \FollowedShow.followedAt) private var followed: [FollowedShow]
    @State private var path: [Drop] = []

    var body: some View {
        NavigationStack(path: $path) {
            UpcomingView(result: model.result, artwork: model.artwork, hasShows: !followed.isEmpty,
                         lastUpdated: model.lastUpdated,
                         onSelect: { path.append($0) }, onFind: onFind, onRefresh: { await model.refresh(followed) })
                .toolbarVisibility(.hidden, for: .navigationBar)
                .navigationDestination(for: Drop.self) { drop in
                    ShowDetailScreen(drop: drop, model: model, artwork: model.artwork[drop.showID])
                }
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
    @State private var reportCopied = false
    @Environment(\.openURL) private var openURL

    init(drop: Drop, model: UpcomingModel, artwork: ShowArtwork?) {
        self.drop = drop
        self.model = model
        self.artwork = artwork
        let key = FollowedShow.key(catalog: drop.showKey.catalog, id: drop.showKey.id)
        _shows = Query(filter: #Predicate<FollowedShow> { $0.key == key })
    }

    var body: some View {
        ShowDetailView(drop: drop, artwork: artwork, episodes: episodes, liveActivity: liveActivity,
                       onReport: report, onUnfollow: unfollow)
            .task { episodes = await model.pastEpisodes(showID: drop.showID) }
            .alert("Couldn't open the report", isPresented: $reportCopied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The report is copied, so you can paste it into an email or a message.")
            }
    }

    /// "Report a wrong time" (D6-3, D-34): a prefilled email while the repo is private, a GitHub issue once public.
    /// Without a mail app the email can't open, so the report goes to the clipboard instead of nowhere.
    private func report() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let formatter = DropFormatter()
        let now = Date.now  // one instant, so the copied text matches the email it stands in for
        guard let url = ReportURLBuilder.url(for: drop, route: .current, now: now, formatter: formatter,
                                             appVersion: version) else { return }
        openURL(url) { opened in
            guard !opened else { return }
            UIPasteboard.general.string = ReportURLBuilder.body(for: drop, now: now, formatter: formatter,
                                                                appVersion: version)
            reportCopied = true
        }
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
