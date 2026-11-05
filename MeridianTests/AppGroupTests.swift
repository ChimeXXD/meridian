import Foundation
import Testing
@testable import Meridian

/// The app and the widgets share one App Group container (D-05). These fail when the entitlement or signing doesn't
/// grant it, which `UserDefaults(suiteName:)` never would: it hands back a store for any name.
@Suite("App Group")
struct AppGroupTests {
    @Test("identifier comes from the build settings")
    func identifierFromInfoPlist() {
        #expect(AppGroup.identifier.hasPrefix("group."))
        #expect(AppGroup.identifier.hasSuffix(".meridian"))
    }

    @Test("the shared container is granted")
    func containerExists() {
        #expect(SnapshotStore.container != nil)
    }

    @Test("a snapshot written to the shared container reads back")
    func snapshotRoundTrip() throws {
        // A folder of its own, so the app's real snapshot.json is left alone.
        let folder = try #require(SnapshotStore.container).appendingPathComponent("tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let drop = Drop(id: "tvmaze:94:1", showID: "94", showName: "House of the Dragon", season: 3, number: 1,
                        episodeTitle: nil, date: Date(iso: "2026-11-02T02:00:00Z"), airdate: nil, confidence: .exact,
                        source: .broadcast(network: "HBO"), provider: nil, previousDate: nil)
        let written = DropSnapshot(generatedAt: Date(iso: "2026-11-01T17:00:00Z"), drops: [drop], nextReturn: nil)
        try SnapshotStore.write(written, to: folder)
        #expect(SnapshotStore.read(from: folder) == written)
    }
}
