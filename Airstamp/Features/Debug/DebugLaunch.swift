#if DEBUG
import SwiftData
import SwiftUI

/// Launch arguments for simulator screenshots of the real app, since the simulator can't tap:
/// `-follow 38052,44778` follows those TVmaze shows (names from TVmaze), `-tab search` or `-tab settings` opens a tab,
/// `-query Euphoria` types into Search, `-kind anime` switches Search to anime, `-filter today` (or `new-seasons`,
/// `exact-time`, `service:Netflix`) picks a Search filter, and `-followAnime 195604` follows those AniList shows.
enum DebugLaunch {
    @MainActor
    static func apply(context: ModelContext, client: TVmazeClient, anilist: AniListClient,
                      tab: Binding<RootView.AppTab>) async {
        let arguments = UserDefaults.standard
        if let ids = arguments.string(forKey: "follow") {
            let store = FollowStore(context: context)
            for id in ids.split(separator: ",").compactMap({ Int($0) }) {
                if let show = try? await client.show(id: id) {
                    try? store.follow(SearchResult(show: show).followShow)
                }
            }
        }
        if let ids = arguments.string(forKey: "followAnime") {
            let store = FollowStore(context: context)
            for id in ids.split(separator: ",").compactMap({ Int($0) }) {
                if let media = try? await anilist.media(id: id) {
                    try? store.follow(SearchResult(media: media).followShow)
                }
            }
        }
        switch arguments.string(forKey: "tab") {
        case "search": tab.wrappedValue = .search
        case "settings": tab.wrappedValue = .settings
        default: break
        }
    }

    static var query: String? { UserDefaults.standard.string(forKey: "query") }
    static var anime: Bool { UserDefaults.standard.string(forKey: "kind") == "anime" }

    static var filter: SearchFilter? {
        switch UserDefaults.standard.string(forKey: "filter") {
        case "today": .today
        case "new-seasons": .newSeasons
        case "exact-time": .exactTime
        case let value? where value.hasPrefix("service:"): .service(String(value.dropFirst("service:".count)))
        default: nil
        }
    }
}
#endif
