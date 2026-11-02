import Foundation
import Testing
@testable import Meridian

/// SPEC: "The app works offline: it shows the last known times with 'Updated <time>'" (D6-2). The line says how old
/// the times on screen are and which shows didn't refresh, naming no source, since a show may come from AniList.
@Suite("Upcoming status")
struct UpcomingStatusTests {
    static let lagos = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
    /// Mon 2 Nov 2026, 19:00 in Lagos.
    static let now = Date(iso: "2026-11-02T18:00:00Z")

    @Test("nothing to say when every show refreshed")
    func allFresh() {
        #expect(UpcomingStatus.line(failed: [], lastUpdated: Self.now, now: Self.now, formatter: Self.lagos) == nil)
    }

    @Test("Updated <time>: today's time alone, another day's with its weekday, then the shows that didn't refresh")
    func offline() {
        let earlier = Self.now - 5 * 3_600
        #expect(UpcomingStatus.line(failed: ["Silo"], lastUpdated: earlier, now: Self.now, formatter: Self.lagos)
            == "Updated 14:00. Couldn't refresh Silo; pull down to try again.")
        #expect(UpcomingStatus.line(failed: ["Silo", "Frieren"], lastUpdated: earlier - 24 * 3_600, now: Self.now,
                                    formatter: Self.lagos)
            == "Updated Sun 14:00. Couldn't refresh Silo and Frieren; pull down to try again.")
    }

    @Test("never updated: only the shows that didn't refresh")
    func neverUpdated() {
        #expect(UpcomingStatus.line(failed: ["Silo"], lastUpdated: nil, now: Self.now, formatter: Self.lagos)
            == "Couldn't refresh Silo; pull down to try again.")
    }
}
