#if DEBUG
import SwiftData
import SwiftUI

/// Launch arguments for simulator screenshots of the real app, since the simulator can't tap:
/// `-follow 38052,44778` follows those TVmaze shows (names from TVmaze), `-tab search` or `-tab settings` opens a tab,
/// and `-query Euphoria` types into Search.
enum DebugLaunch {
    @MainActor
    static func apply(context: ModelContext, client: TVmazeClient, tab: Binding<RootView.AppTab>) async {
        let arguments = UserDefaults.standard
        if let ids = arguments.string(forKey: "follow") {
            let store = FollowStore(context: context)
            for id in ids.split(separator: ",").compactMap({ Int($0) }) {
                if let show = try? await client.show(id: id) {
                    try? store.follow(SearchResult(show: show).followShow)
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
}
#endif
