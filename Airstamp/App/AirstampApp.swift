import SwiftData
import SwiftUI

@main
struct AirstampApp: App {
    private let client = TVmazeClient()
    private let anilist = AniListClient()
    @State private var model: UpcomingModel

    init() {
        // The bundled rules only while the repo is private (D-34); the remote fetch switches on at Day 7.
        let rules = (try? RulesStore.loadBundled())
            ?? RulesFile(schemaVersion: 1, updated: "", platforms: [], overrides: [], providers: [])
        // The country from the time zone (D2-6), so Lagos means Nigeria whatever the region setting says.
        let country = (try? ViewerCountry.loadBundled())?.code(zone: TimeZone.current.identifier,
                                                               region: Locale.current.region?.identifier)
        _model = State(initialValue: UpcomingModel(client: client, anilist: anilist, rules: rules,
                                                   viewerCountry: country))
    }

    var body: some Scene {
        WindowGroup {
            content
        }
        .modelContainer(for: FollowedShow.self, inMemory: Self.inMemoryStore)
    }

    /// Debug `-inMemoryStore` starts with nothing followed, for the fidelity checks of Welcome and empty states.
    private static var inMemoryStore: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-inMemoryStore")
        #else
        false
        #endif
    }

    @ViewBuilder private var content: some View {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-designPreview") {
            DesignPreview()
        } else if arguments.contains("-setupCheck") {
            PlaceholderView()
        } else {
            RootView(client: client, anilist: anilist, model: model)
        }
        #else
        RootView(client: client, anilist: anilist, model: model)
        #endif
    }
}
