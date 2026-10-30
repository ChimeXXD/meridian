import Foundation

/// The words and status of a source chip (CLAUDE.md rule 3). An override reads "Confirmed" only when
/// it resolved as exact; otherwise it is "Adjusted".
struct SourceChipContent: Hashable, Sendable {
    let label: String
    let kind: SourceKind

    init(source: ReleaseSource, confidence: Confidence) {
        switch source {
        case .broadcast: (label, kind) = ("Broadcast", .exact)
        case .platformRule(let name): (label, kind) = (name, .estimated)
        case .override: (label, kind) = confidence == .exact ? ("Confirmed", .exact) : ("Adjusted", .adjusted)
        case .adjusted: (label, kind) = ("Adjusted", .adjusted)
        case .anilist: (label, kind) = ("JP broadcast", .exact)
        case .dateOnly: (label, kind) = ("Date only", .dateOnly)
        }
    }
}
