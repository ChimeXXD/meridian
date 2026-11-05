import Foundation
import Testing
@testable import Meridian

final class FixtureBundleToken {}

/// Loads recorded API JSON from the test bundle's `Fixtures/` folder.
enum Fixture {
    static var root: URL {
        Bundle(for: FixtureBundleToken.self).resourceURL!.appendingPathComponent("Fixtures")
    }

    static func data(_ relativePath: String) throws -> Data {
        try Data(contentsOf: root.appendingPathComponent(relativePath))
    }

    static func ruleCases() throws -> [RuleCase] {
        let folder = root.appendingPathComponent("rules")
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        let decoder = JSONDecoder.rules
        return try files.map { url in
            var item = try decoder.decode(RuleCase.self, from: Data(contentsOf: url))
            item.slug = url.deletingPathExtension().lastPathComponent
            return item
        }
    }

    static func bundledRules() throws -> RulesFile {
        try RulesStore.loadBundled(from: Bundle.main)
    }
}

/// A recorded TVmaze episode plus the release time an independent source confirmed.
struct RuleCase: Decodable {
    struct Expected: Decodable {
        let instant: Date?
        let confidence: Confidence
        let source: String
        let note: String
    }

    var slug = ""
    let show: TVmazeShow
    let episode: TVmazeEpisode
    let expected: Expected

    enum CodingKeys: String, CodingKey { case show, episode, expected }
}

extension RuleCase: CustomTestStringConvertible {
    /// A parameterised test names each case by its file.
    var testDescription: String { slug }
}

extension Date {
    /// Builds a UTC instant from an ISO 8601 literal in tests.
    init(iso: String) {
        self = try! Date(iso, strategy: .iso8601)
    }
}
