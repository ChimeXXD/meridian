import SwiftUI

/// Settings (SPEC §1, UI-BRIEF §5.6): the zone Airstamp uses, the Live Activity lead time, credits and privacy. The
/// zone override (a Should) and the Live Activities permission state join with the scheduler.
struct SettingsView: View {
    var formatter = DropFormatter()

    @AppStorage(LeadTime.storageKey) private var leadMinutes = LeadTime.defaultMinutes

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
                } footer: {
                    Text("The release-night Live Activity starts this long before an episode is out.")
                }
                Section {
                    NavigationLink("Credits & licences") { CreditsView() }
                        .accessibilityIdentifier("settings-credits")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

/// Credits (SPEC §1, UI-BRIEF §5.7): where the data comes from, its licences, and that nothing is collected.
struct CreditsView: View {
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
            }
            Section {
                Text("Airstamp is open source under the MIT licence")
                    .accessibilityIdentifier("credits-licence")
                Text("Airstamp collects no data. Nothing leaves your phone except requests to TVmaze and AniList.")
                    .accessibilityIdentifier("credits-no-data")
            }
        }
        .navigationTitle("Credits & licences")
    }
}
