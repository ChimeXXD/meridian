import Foundation

/// A platform offered as a Search filter chip, and the exact TVmaze network or web channel names it covers.
struct PopularService: Hashable, Sendable {
    let label: String
    let names: [String]
}

/// The platforms that get a chip (Chime, 1 Nov 2026: "the popular platforms that most people use"; D-45): the big
/// streamers by reported paid subscribers, then the four big US networks. Every one always has a chip, in this order,
/// even with nothing coming; every other service (YouTube, BBC iPlayer, small channels) gets no chip, though its shows
/// still appear under Popular and the other filters.
enum PopularServices {
    /// Most subscribers first (2026 estimates: Netflix ~325M, Prime Video ~205M, HBO Max ~140M, Disney+ ~132M,
    /// Paramount+ ~79M, Hulu ~64M, Peacock ~46M; Apple TV publishes none), then CBS, NBC, ABC and FOX.
    static let all: [PopularService] = [
        PopularService(label: "Netflix", names: ["Netflix"]),
        PopularService(label: "Prime Video", names: ["Prime Video"]),
        PopularService(label: "HBO Max", names: ["HBO Max", "HBO"]),
        PopularService(label: "Disney+", names: ["Disney+"]),
        PopularService(label: "Paramount+", names: ["Paramount+", "Paramount+ with Showtime"]),
        PopularService(label: "Hulu", names: ["Hulu"]),
        PopularService(label: "Peacock", names: ["Peacock"]),
        PopularService(label: "Apple TV", names: ["Apple TV", "Apple TV+"]),
        PopularService(label: "CBS", names: ["CBS"]),
        PopularService(label: "NBC", names: ["NBC"]),
        PopularService(label: "ABC", names: ["ABC"]),
        PopularService(label: "FOX", names: ["FOX"]),
    ]

    static func service(_ label: String) -> PopularService? {
        all.first { $0.label == label }
    }
}
