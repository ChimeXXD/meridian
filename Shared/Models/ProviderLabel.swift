import Foundation

/// The origin network or channel and its country, e.g. "HBO · US" (D-20).
struct ProviderLabel: Codable, Hashable, Sendable {
    var name: String
    var countryCode: String?
    var noOfficialStream: Bool

    var display: String {
        guard let countryCode else { return name }
        return "\(name) · \(countryCode)"
    }
}
