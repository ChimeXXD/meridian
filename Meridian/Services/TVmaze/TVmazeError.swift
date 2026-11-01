import Foundation

enum TVmazeError: Error, Equatable {
    /// Still HTTP 429 after every retry.
    case rateLimited
    case http(status: Int)
    case invalidResponse
}
