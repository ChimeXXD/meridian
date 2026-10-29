import Foundation

/// Why a rules file was rejected. A rejected remote file falls back to the bundled copy.
enum RulesValidationError: Error, Equatable {
    case unsupportedSchema(Int)
    case invalidPlatform(String)
    case invalidOverride(String)
    case invalidProvider(String)
}
