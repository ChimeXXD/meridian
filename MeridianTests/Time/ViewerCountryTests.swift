import Foundation
import Testing
@testable import Meridian

/// The viewer's country comes from their time zone (D2-6), so "No official stream in your country" is right for Lagos
/// even when the phone's region setting says otherwise. The device region is only a fallback.
@Suite("Viewer country")
struct ViewerCountryTests {
    static let table = ViewerCountry(table: ["Africa/Lagos": "NG", "Europe/London": "GB", "America/New_York": "US"])

    @Test("the zone decides the country", arguments: [
        ("Africa/Lagos", "NG"), ("Europe/London", "GB"), ("America/New_York", "US"),
    ])
    func fromZone(zone: String, expected: String) {
        #expect(Self.table.code(zone: zone, region: "GB") == expected)
    }

    @Test("an unknown zone falls back to the device region")
    func fallback() {
        #expect(Self.table.code(zone: "Etc/UTC", region: "NG") == "NG")
        #expect(Self.table.code(zone: "Etc/UTC", region: nil) == nil)
    }

    @Test("the bundled table covers the tz database, including Lagos")
    func bundled() throws {
        let bundled = try ViewerCountry.loadBundled()
        #expect(bundled.code(zone: "Africa/Lagos", region: nil) == "NG")
        #expect(bundled.code(zone: "Asia/Tokyo", region: nil) == "JP")
        #expect(bundled.count > 400)
    }
}
