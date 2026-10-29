import Foundation

/// The release rules: platform rules, overrides and provider availability (SPEC §3.2, D-18).
/// Bundled with the app; a remote copy is used only when the repo is public (D-34).
struct RulesFile: Codable, Hashable, Sendable {
    var schemaVersion: Int
    var updated: String
    var platforms: [PlatformRule]
    var overrides: [ReleaseOverride]
    var providers: [ProviderRule]

    static func decode(_ data: Data) throws -> RulesFile {
        try JSONDecoder.rules.decode(RulesFile.self, from: data)
    }

    func platform(matching names: [String]) -> PlatformRule? {
        let wanted = Set(names.map { $0.lowercased() })
        return platforms.first { rule in rule.match.contains { wanted.contains($0.lowercased()) } }
    }

    func override(forEpisode id: String) -> ReleaseOverride? {
        overrides.first { $0.episode == id }
    }

    func override(forShow id: String) -> ReleaseOverride? {
        overrides.first { $0.show == id && $0.episode == nil }
    }

    func validate() throws {
        guard schemaVersion == 1 else { throw RulesValidationError.unsupportedSchema(schemaVersion) }
        var claimedNames: Set<String> = []
        for rule in platforms {
            // A name in two rules would let file order decide which applies.
            for name in rule.match.map({ $0.lowercased() }) where !claimedNames.insert(name).inserted {
                throw RulesValidationError.invalidPlatform(rule.label)
            }
            guard !rule.match.isEmpty, !rule.label.isEmpty, rule.sources.count >= 2,
                  WallClock.isValidZone(rule.zone), WallClock.parseTime(rule.time) != nil else {
                throw RulesValidationError.invalidPlatform(rule.label)
            }
        }
        for item in overrides {
            let target = item.episode ?? item.show ?? "?"
            guard (item.episode == nil) != (item.show == nil), !item.source.isEmpty else {
                throw RulesValidationError.invalidOverride(target)
            }
            let hasWallClock = item.zone.map(WallClock.isValidZone) == true && item.time.flatMap(WallClock.parseTime) != nil
            // A show override must be a wall-clock time; an instant would pin every episode to one moment.
            let hasAnyWallClock = item.zone != nil || item.time != nil || item.dayOffset != nil
            // Exactly one way to give the time: an instant (episodes only) or a wall-clock time.
            let valid = item.show != nil
                ? (item.instant == nil && hasWallClock)
                : (item.instant != nil ? !hasAnyWallClock : hasWallClock)
            guard valid else { throw RulesValidationError.invalidOverride(target) }
        }
        for provider in providers where provider.match.isEmpty || provider.source.isEmpty {
            throw RulesValidationError.invalidProvider(provider.match.first ?? "?")
        }
    }
}

extension JSONDecoder {
    /// Decodes rules files, whose instants are ISO 8601 strings.
    static var rules: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var rules: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
