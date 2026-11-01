import SwiftUI

/// Settings (SPEC §1, UI-BRIEF §5.6): the zone Airstamp uses, the Live Activity lead time and whether Live Activities
/// are allowed, credits and privacy, and the Debug menu in Debug builds. The zone override (a Should) is still to come.
struct SettingsView: View {
    let scheduler: ActivityScheduler
    /// For the Debug menu's fake drop, which reloads Upcoming.
    let model: UpcomingModel
    var formatter = DropFormatter()

    @AppStorage(LeadTime.storageKey) private var leadMinutes = LeadTime.defaultMinutes
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section("Time zone") {
                    LabeledContent("Automatic", value: ReleaseWording.zoneSummary(formatter, at: .now))
                        .accessibilityIdentifier("settings-zone")
                }
                Section {
                    Picker("Live Activity lead time", selection: $leadMinutes) {
                        ForEach(LeadTime.choices, id: \.self) { minutes in
                            Text(LeadTime.phrase(minutes: minutes)).tag(minutes)
                        }
                    }
                    .accessibilityIdentifier("settings-lead")
                    permission
                } footer: {
                    Text("The release-night Live Activity starts this long before an episode is out.")
                }
                Section {
                    NavigationLink("Credits & licences") { CreditsView() }
                        .accessibilityIdentifier("settings-credits")
                }
                #if DEBUG
                Section {
                    NavigationLink("Debug") { DebugMenuView(model: model, scheduler: scheduler) }
                        .accessibilityIdentifier("settings-debug")
                }
                #endif
            }
            .navigationTitle("Settings")
        }
        // The switch lives in iOS Settings, so read it again whenever the user may have come back from there.
        .onAppear { scheduler.refreshPermission() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { scheduler.refreshPermission() }
        }
    }

    /// Whether Live Activities are allowed, in plain words, with a way to iOS Settings when they're off (UI-BRIEF §5.6).
    @ViewBuilder private var permission: some View {
        if scheduler.activitiesEnabled {
            Text("Live Activities are on")
                .accessibilityIdentifier("settings-la-permission")
        } else {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text("Live Activities are off in Settings › Airstamp")
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .accessibilityIdentifier("settings-la-open")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("settings-la-permission")
        }
    }
}

/// Credits (SPEC §1, UI-BRIEF §5.7): where the data comes from, its licences, and that nothing is collected.
struct CreditsView: View {
    /// Credit lines for the logo files whose licence asks for one (D-44).
    private static let logoCredits = NetworkLogos.bundled.credits

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text("Show and episode data from TVmaze, licensed under CC BY-SA 4.0")
                    Link("tvmaze.com", destination: URL(string: "https://www.tvmaze.com")!)
                        .accessibilityIdentifier("credits-tvmaze-link")
                }
                .accessibilityIdentifier("credits-tvmaze")
                Text("Anime schedules from AniList")
                    .accessibilityIdentifier("credits-anilist")
                Text("Show artwork is loaded from TVmaze while the app runs and kept only on your phone")
                    .accessibilityIdentifier("credits-artwork")
                Text("Service logos from Wikimedia Commons, each under its own free licence")
                    .accessibilityIdentifier("credits-logos")
                ForEach(Self.logoCredits, id: \.self) { Text($0).font(.footnote) }
            }
            Section {
                Text("Airstamp is open source under the MIT licence")
                    .accessibilityIdentifier("credits-licence")
                Text("Airstamp collects no data. Nothing leaves your phone except requests to TVmaze, AniList and Wikimedia.")
                    .accessibilityIdentifier("credits-no-data")
            }
        }
        .navigationTitle("Credits & licences")
    }
}
