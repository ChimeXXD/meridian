import Foundation
import Testing
@testable import Meridian

/// D6-5, SPEC: "The accuracy audit shows 20 of 20 real drops from the build week correct, including drops on either
/// side of the 1 Nov 2026 US clock change, in the tester's zone." Each case in `Fixtures/audit/` is a real episode's
/// TVmaze data with the release time an independent source confirmed (`scripts/record-fixtures.py --audit`).
/// Correct means the Lagos day is right and the time within 5 minutes; a date-only drop is correct if its date is right
/// and it shows no time, and at most 4 of the 20 may be date-only. `docs/research/accuracy-audit.md` lists the rows.
@Suite("Accuracy audit")
struct AccuracyAuditTests {
    static let tolerance: TimeInterval = 5 * 60
    static let lagos = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
    /// The US clock change, 1 Nov 2026 02:00 EDT.
    static let clockChange = Date(iso: "2026-11-01T06:00:00Z")

    struct Case: Decodable {
        struct Expected: Decodable {
            let instant: Date
            let source: String
            let note: String
        }

        var slug = ""
        let show: TVmazeShow
        let episode: TVmazeEpisode
        let expected: Expected

        enum CodingKeys: String, CodingKey { case show, episode, expected }
    }

    static func cases() throws -> [Case] {
        let folder = Fixture.root.appendingPathComponent("audit")
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return try files.map { url in
            var item = try JSONDecoder.rules.decode(Case.self, from: Data(contentsOf: url))
            item.slug = url.deletingPathExtension().lastPathComponent
            return item
        }
    }

    @Test("20 real drops from the build week, each right in Lagos (SPEC's definition)")
    func twentyOfTwenty() throws {
        let rules = try Fixture.bundledRules()
        let cases = try Self.cases()
        #expect(cases.count >= 20, "the audit needs 20 drops, has \(cases.count)")

        var dateOnly = 0
        for item in cases {
            let result = TimeResolver.resolve(item.episode.listing(show: item.show), rules: rules)
            let confirmedDay = Self.lagos.localDay(item.expected.instant)
            if result.confidence == .dateOnly {
                dateOnly += 1
                #expect(result.airdate == confirmedDay,
                        "\(item.slug): date only, listed \(result.airdate ?? "none"), out \(confirmedDay) in Lagos")
            } else {
                let gap = result.date.timeIntervalSince(item.expected.instant)
                #expect(Self.lagos.localDay(result.date) == confirmedDay, "\(item.slug): wrong day in Lagos")
                #expect(abs(gap) <= Self.tolerance,
                        "\(item.slug): off by \(Int(gap / 60)) min (\(item.expected.note))")
            }
            // One row a case, for docs/research/accuracy-audit.md.
            let shown = result.confidence == .dateOnly
                ? "\(result.airdate ?? "?"), no time"
                : "\(Self.lagos.weekdayTime(result.date)) (\(result.confidence.rawValue))"
            print("AUDIT|\(item.slug)|\(shown)|\(Self.lagos.weekdayTime(item.expected.instant))|\(item.expected.source)")
        }
        #expect(dateOnly <= 4, "\(dateOnly) of the drops are date only; SPEC allows 4")
    }

    @Test("drops on both sides of the 1 Nov US clock change")
    func clockChange() throws {
        let instants = try Self.cases().map(\.expected.instant)
        #expect(instants.contains { $0 < Self.clockChange }, "no drop before the clock change")
        #expect(instants.contains { $0 >= Self.clockChange }, "no drop after the clock change")
    }
}
