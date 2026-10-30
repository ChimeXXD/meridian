import SwiftData
import SwiftUI

/// The app's top level (D-41): the one-screen Welcome on first run, then a tab bar with Upcoming, Search and
/// Settings.
struct RootView: View {
    enum AppTab: Hashable { case upcoming, search, settings }

    let client: TVmazeClient
    let anilist: AniListClient
    let model: UpcomingModel

    @Environment(\.modelContext) private var context
    @Query private var followed: [FollowedShow]
    @AppStorage("welcomeDone") private var welcomeDone = false
    @State private var tab = AppTab.upcoming

    var body: some View {
        content
            #if DEBUG
            // On the root, not the tab bar, so `-follow` also works on a fresh install that opens on Welcome.
            .task { await DebugLaunch.apply(context: context, client: client, anilist: anilist, tab: $tab) }
            #endif
    }

    @ViewBuilder private var content: some View {
        if !welcomeDone && followed.isEmpty {
            WelcomeView(onFind: { welcomeDone = true; tab = .search }, onLater: { welcomeDone = true })
        } else {
            TabView(selection: $tab) {
                Tab("Upcoming", systemImage: "clock", value: .upcoming) {
                    UpcomingTab(model: model, onFind: { tab = .search })
                }
                // Search sits in the middle (Chime). A `.search` role tab always floats on the trailing edge on iOS 26,
                // so this is a plain tab.
                Tab("Search", systemImage: "magnifyingglass", value: .search) {
                    SearchView(client: client, anilist: anilist)
                }
                Tab("Settings", systemImage: "gearshape", value: .settings) {
                    SettingsView()
                }
            }
            .tint(.white)
            .environment(\.colorScheme, .dark)
        }
    }
}
