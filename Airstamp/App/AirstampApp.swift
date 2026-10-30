import SwiftData
import SwiftUI

@main
struct AirstampApp: App {
    private let client = TVmazeClient()
    @State private var model: UpcomingModel

    init() {
        // The bundled rules only while the repo is private (D-34); the remote fetch switches on at Day 7.
        let rules = (try? RulesStore.loadBundled())
            ?? RulesFile(schemaVersion: 1, updated: "", platforms: [], overrides: [], providers: [])
        _model = State(initialValue: UpcomingModel(client: client, rules: rules,
                                                   viewerCountry: Locale.current.region?.identifier))
    }

    var body: some Scene {
        WindowGroup {
            content
        }
        .modelContainer(for: FollowedShow.self)
    }

    @ViewBuilder private var content: some View {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-designPreview") {
            DesignPreview()
        } else if arguments.contains("-setupCheck") {
            PlaceholderView()
        } else {
            RootView(client: client, model: model)
        }
        #else
        RootView(client: client, model: model)
        #endif
    }
}
