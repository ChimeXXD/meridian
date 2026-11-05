import SwiftData
import SwiftUI
import UIKit

/// The Upcoming tab: the followed shows from SwiftData, loaded through `UpcomingModel`, with Show detail pushed on
/// tap. `RootView` reloads it when the followed list changes and each time the app becomes active (D-27); here it
/// reloads on pull-to-refresh.
struct UpcomingTab: View {
    let model: UpcomingModel
    let scheduler: ActivityScheduler
    var onFind: () -> Void = {}

    @Query(sort: \FollowedShow.followedAt) private var followed: [FollowedShow]
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            UpcomingView(result: model.result, artwork: model.artwork, hasShows: !followed.isEmpty,
                         lastUpdated: model.lastUpdated,
                         onSelect: { path.append($0) }, onSelectQuiet: { path.append($0) }, onFind: onFind,
                         onRefresh: { await model.refresh(followed) })
                .toolbarVisibility(.hidden, for: .navigationBar)
                .navigationDestination(for: Drop.self) { drop in
                    ShowDetailScreen(drop: drop, model: model, scheduler: scheduler, artwork: model.artwork[drop.showID])
                }
                .navigationDestination(for: QuietShow.self) { show in
                    QuietShowScreen(show: show, model: model, artwork: model.artwork[show.showID])
                }
        }
    }
}

/// Show detail for a followed show: its Live Activity switch is stored on the show, and unfollow removes it.
struct ShowDetailScreen: View {
    let drop: Drop
    let model: UpcomingModel
    let scheduler: ActivityScheduler
    let artwork: ShowArtwork?

    @Environment(\.modelContext) private var context
    @Query private var shows: [FollowedShow]
    @State private var episodes: [PastEpisode] = []
    @State private var reportCopied = false
    @Environment(\.openURL) private var openURL

    init(drop: Drop, model: UpcomingModel, scheduler: ActivityScheduler, artwork: ShowArtwork?) {
        self.drop = drop
        self.model = model
        self.scheduler = scheduler
        self.artwork = artwork
        // The debug show isn't followed, so its key matches nothing.
        let key = drop.show?.key ?? ""
        _shows = Query(filter: #Predicate<FollowedShow> { $0.key == key })
    }

    var body: some View {
        ShowDetailView(drop: current, artwork: artwork, episodes: episodes, liveActivity: liveActivity,
                       offset: offset, activityStatus: activityStatus, onReport: report, onUnfollow: unfollow)
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
        let drop = current  // the time on screen, not the one the page opened with
        guard let url = ReportURLBuilder.url(for: drop, route: .current, now: now, formatter: formatter,
                                             appVersion: version) else { return }
        openURL(url) { opened in
            guard !opened else { return }
            UIPasteboard.general.string = ReportURLBuilder.body(for: drop, now: now, formatter: formatter,
                                                                appVersion: version)
            reportCopied = true
        }
    }

    /// The show's latest drop, so a refresh while this page is open (a delay, a new stream delay) shows here too
    /// (UX audit #14); the drop it was opened with until then. The same episode first, then the show's.
    private var current: Drop {
        let drops = model.result?.drops ?? []
        return drops.first { $0.id == drop.id } ?? drops.first { $0.showID == drop.showID && !Self.isFake($0) } ?? drop
    }

    /// Debug's copy of a real drop shares its show, so a real row mustn't open on the copy's time.
    private static func isFake(_ drop: Drop) -> Bool {
        #if DEBUG
        DebugFakeDrop.isFake(drop)
        #else
        false
        #endif
    }

    /// What the Live Activity switch will really do for this episode (UX audit #11).
    private var activityStatus: LiveActivityStatus.Line {
        let waiting = (scheduler.lastOutcome?.skippedOverLimit ?? []).joined().contains(current.id)
        return LiveActivityStatus.line(isOn: liveActivity.wrappedValue, systemEnabled: scheduler.activitiesEnabled,
                                       drop: current, waiting: waiting, now: .now)
    }

    /// The anime stream delay, stored on the show; RootView refreshes when it changes.
    private var offset: Binding<Int>? {
        guard let show = shows.first, AnimeOffset.applies(to: current, catalog: show.catalog) else { return nil }
        return Binding(get: { show.animeOffsetMinutes },
                       set: { value in
                           show.animeOffsetMinutes = value
                           try? context.save()
                       })
    }

    private var liveActivity: Binding<Bool> {
        Binding(get: { shows.first?.liveActivity ?? true },
                set: { value in
                    shows.first?.liveActivity = value
                    try? context.save()
                })
    }

    private func unfollow() {
        guard let show = drop.show else { return }
        try? FollowStore(context: context).unfollow(catalog: show.catalog, id: show.id)
    }
}

/// A quiet show's page (UX audit #12): its last episodes, and Unfollow removes it.
struct QuietShowScreen: View {
    let show: QuietShow
    let model: UpcomingModel
    let artwork: ShowArtwork?

    @Environment(\.modelContext) private var context
    @State private var episodes: [PastEpisode] = []

    var body: some View {
        QuietShowView(show: show, artwork: artwork, episodes: episodes) {
            guard let id = ShowID(show.showID) else { return }
            try? FollowStore(context: context).unfollow(catalog: id.catalog, id: id.id)
        }
        .task { episodes = await model.pastEpisodes(showID: show.showID) }
    }
}
