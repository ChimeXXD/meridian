import SwiftData
import SwiftUI

/// The app's top level (D-41): the one-screen Welcome on first run, then a tab bar with Upcoming, Search and
/// Settings. Upcoming reloads from here, when the followed list changes and each time the app becomes active (D-27),
/// whichever tab is open, so a follow in Search or an unfollow reaches the widgets at once (D4-1). After each reload
/// the release-night Live Activities are scheduled from the fresh drops (SPEC §6, D-10).
struct RootView: View {
    enum AppTab: Hashable { case upcoming, search, settings }

    let client: TVmazeClient
    let anilist: AniListClient
    let model: UpcomingModel
    let scheduler: ActivityScheduler

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \FollowedShow.followedAt) private var followed: [FollowedShow]
    @AppStorage("welcomeDone") private var welcomeDone = false
    @AppStorage(LeadTime.storageKey) private var leadMinutes = LeadTime.defaultMinutes
    @State private var tab = AppTab.upcoming

    var body: some View {
        // Welcome hands over to the tabs with a crossfade, not a cut (AD-7); a fade moves nothing, so it stays under
        // Reduce Motion.
        ZStack { content }
            .animation(.smooth(duration: 0.4), value: showsWelcome)
            // A follow, an unfollow or an anime's new stream delay reloads the times.
            .task(id: followed.map { "\($0.key):\($0.animeOffsetMinutes)" }) { await refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await refresh() } }
            }
            // A show's Live Activity switch flipped in Show detail schedules or cancels it at once, without a reload.
            .onChange(of: optedIn) { Task { await syncActivities() } }
            // A new lead time books again the activities that haven't started, so they start at it (UX audit #13).
            .onChange(of: leadMinutes) { Task { await syncActivities(rebookPending: true) } }
            #if DEBUG
            // On the root, not the tab bar, so `-follow` also works on a fresh install that opens on Welcome.
            .task { await DebugLaunch.apply(context: context, client: client, anilist: anilist, tab: $tab) }
            .task { await DebugLaunch.startFakeActivity(scheduler: scheduler) }
            #endif
    }

    /// The followed shows whose release-night Live Activity is on, as `Drop.showID`s.
    private var optedIn: Set<String> { Set(followed.filter(\.liveActivity).map(\.showID)) }

    /// Upcoming first, then the Live Activities from its drops (SPEC §6), so they're scheduled from fresh times.
    private func refresh() async {
        await model.refresh(followed)
        await syncActivities()
    }

    /// ActivityKit only accepts requests while the app is in the foreground (CLAUDE.md rule 6). The initial task can
    /// run before the scene is active; the activation that follows syncs then.
    private func syncActivities(rebookPending: Bool = false) async {
        guard UIApplication.shared.applicationState == .active else { return }
        let optedOut = Set(followed.filter { !$0.liveActivity }.map(\.showID))
        var drops = model.result?.drops ?? []
        #if DEBUG
        // Debug's copy of a real drop is booked once by the Debug menu, never again with the real lead time.
        drops.removeAll(where: DebugFakeDrop.isFake)
        #endif
        await scheduler.sync(drops: drops, optedIn: optedIn, optedOut: optedOut,
                             leadMinutes: leadMinutes, rebookPending: rebookPending)
    }

    private var showsWelcome: Bool { !welcomeDone && followed.isEmpty }

    @ViewBuilder private var content: some View {
        if showsWelcome {
            WelcomeView(client: client, anilist: anilist, rules: model.rules,
                        onFind: { welcomeDone = true; tab = .search }, onLater: { welcomeDone = true })
                .transition(.opacity)
        } else {
            TabView(selection: $tab) {
                Tab("Upcoming", systemImage: "clock", value: .upcoming) {
                    UpcomingTab(model: model, scheduler: scheduler, onFind: { tab = .search })
                }
                // Search sits in the middle (Chime). A `.search` role tab always floats on the trailing edge on iOS 26,
                // so this is a plain tab.
                Tab("Search", systemImage: "magnifyingglass", value: .search) {
                    SearchView(client: client, anilist: anilist, rules: model.rules)
                }
                Tab("Settings", systemImage: "gearshape", value: .settings) {
                    SettingsView(scheduler: scheduler, model: model)
                }
            }
            .tint(.white)
            .environment(\.colorScheme, .dark)
            .transition(.opacity)
        }
    }
}
