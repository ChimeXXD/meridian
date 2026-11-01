#if DEBUG
import SwiftData
import SwiftUI
import UIKit

/// The Debug menu (Debug builds only; D-11, SPEC §7, D5-3), pushed from Settings. A fake drop to watch a countdown
/// reach zero, a Live Activity for it, the widgets' snapshot as text, and a simulated delay.
struct DebugMenuView: View {
    let model: UpcomingModel
    let scheduler: ActivityScheduler

    @Query(sort: \FollowedShow.followedAt) private var followed: [FollowedShow]
    @State private var status: String?

    var body: some View {
        List {
            Section {
                ForEach([2, 10, 60], id: \.self) { minutes in
                    Button("Fake drop in \(minutes) minutes") { Task { await fakeDrop(minutes: minutes) } }
                        .accessibilityIdentifier("debug-fake-\(minutes)")
                }
                Button("Remove fake drop", role: .destructive) { Task { await removeFakeDrop() } }
                    .accessibilityIdentifier("debug-fake-remove")
            } header: {
                Text("Fake drop")
            } footer: {
                Text("Adds “Debug Show” to Upcoming and the widgets until the app is relaunched.")
            }
            Section("Live Activity") {
                Button("Live Activity for fake drop in 3 min (lead 1 min)") { Task { await fakeActivity() } }
                    .accessibilityIdentifier("debug-activity")
                Button("Simulate delay +1 h") { Task { await delay() } }
                    .accessibilityIdentifier("debug-delay")
            }
            Section {
                NavigationLink("Dump snapshot") { DebugSnapshotView() }
                    .accessibilityIdentifier("debug-snapshot")
            }
            if let status {
                Section("Last action") {
                    Text(status).accessibilityIdentifier("debug-status")
                }
            }
        }
        .navigationTitle("Debug")
    }

    private func fakeDrop(minutes: Int) async {
        let drop = DebugFakeDrop.set(minutes: Double(minutes))
        await model.refresh(followed)
        status = "Fake drop at \(DropFormatter().localTime(drop.date)), in Upcoming and the widgets."
    }

    private func removeFakeDrop() async {
        DebugFakeDrop.clear()
        await model.refresh(followed)
        status = "Fake drop removed."
    }

    /// Requests the activity first, while the app is surely in the foreground, then shows the drop in Upcoming.
    private func fakeActivity() async {
        let drop = DebugFakeDrop.set(minutes: 3)
        let outcome = await scheduler.sync(drops: [drop], optedIn: [DebugFakeDrop.showID], leadMinutes: 1)
        status = Self.describe(outcome, drop: drop)
        await model.refresh(followed)
    }

    private func delay() async {
        DebugFakeDrop.delay(by: 3_600)
        let count = await scheduler.delayAll(by: 3_600)
        await model.refresh(followed)
        status = count == 0 ? "No Live Activity running; the fake drop (if any) moved 1 hour later."
            : "Moved \(count) Live \(count == 1 ? "Activity" : "Activities") 1 hour later."
    }

    private static func describe(_ outcome: ActivityScheduler.Outcome, drop: Drop) -> String {
        if !outcome.enabled { return "Live Activities are off in Settings › Airstamp." }
        if !outcome.requested.isEmpty {
            return "Requested: it appears at \(DropFormatter().localTime(drop.date.addingTimeInterval(-60))), "
                + "drop at \(DropFormatter().localTime(drop.date))."
        }
        if !outcome.skippedOverLimit.isEmpty { return "Skipped: 3 Live Activities are already pending." }
        return "The request failed."
    }
}

/// The App Group `snapshot.json` the widgets read, pretty-printed and selectable, with a Copy button.
struct DebugSnapshotView: View {
    @State private var text = ""

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Tokens.Space.m)
                .accessibilityIdentifier("debug-snapshot-text")
        }
        .navigationTitle("snapshot.json")
        .toolbar {
            Button("Copy") { UIPasteboard.general.string = text }
                .accessibilityIdentifier("debug-snapshot-copy")
        }
        .onAppear { text = Self.load() }
    }

    static func load() -> String {
        guard let container = SnapshotStore.container else { return "No App Group container: the entitlement is missing." }
        let url = container.appendingPathComponent(SnapshotStore.fileName)
        guard let data = try? Data(contentsOf: url) else { return "No snapshot written yet." }
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object,
                                                       options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        else { return String(decoding: data, as: UTF8.self) }
        return String(decoding: pretty, as: UTF8.self)
    }
}
#endif
