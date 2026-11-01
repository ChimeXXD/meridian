import Foundation
import Testing
@testable import Meridian

/// The Live Activity lead time: 30 min to 6 h, default 2 h (SPEC §1, Settings).
@Suite("Lead time")
struct LeadTimeTests {
    @Test("the choices run from 30 minutes to 6 hours, with 2 hours as the default")
    func choices() {
        #expect(LeadTime.choices == [30, 60, 120, 180, 240, 360])
        #expect(LeadTime.defaultMinutes == 120)
    }

    @Test("reads as words", arguments: [(1, "1 minute"), (30, "30 minutes"), (60, "1 hour"), (120, "2 hours"), (360, "6 hours")])
    func phrase(minutes: Int, expected: String) {
        #expect(LeadTime.phrase(minutes: minutes) == expected)
    }
}
