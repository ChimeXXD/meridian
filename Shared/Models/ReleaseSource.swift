import Foundation

/// Where a displayed time came from. The views say how sure it is in words (`ReleaseWording`), and Show detail
/// explains the source in one sentence (D-40).
enum ReleaseSource: Codable, Hashable, Sendable {
    /// TVmaze airtime in the network's own time zone.
    case broadcast(network: String)
    /// A platform rule from the rules file, e.g. "Netflix rule".
    case platformRule(String)
    /// A per-episode or per-show override from the rules file (D-18).
    case override(note: String)
    /// A user offset applied on top of another source, e.g. an anime stream delay on its Japanese TV time.
    indirect case adjusted(base: ReleaseSource, offsetMinutes: Int)
    /// AniList `airingAt`: the Japanese broadcast time.
    case anilist
    case dateOnly

    /// A short name for the underlying source, used when an offset adjusts it.
    var baseLabel: String {
        switch self {
        case .broadcast(let network): network
        case .platformRule(let label): label
        case .override(let note): note
        case .adjusted(let base, _): base.baseLabel
        case .anilist: "JP broadcast"
        case .dateOnly: "Date only"
        }
    }
}

extension ReleaseSource {
    /// Reads every source as Swift's synthesized coding writes it. An `adjusted` source written before its base was a
    /// source carries the base's label instead (`{"base":"JP broadcast"}`), so that still reads, as the source the
    /// label came from: a snapshot (D-05) from an older build must keep decoding.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first, container.allKeys.count == 1 else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath,
                                                    debugDescription: "A release source has exactly one case."))
        }
        switch key {
        case .broadcast:
            let values = try container.nestedContainer(keyedBy: BroadcastCodingKeys.self, forKey: key)
            self = .broadcast(network: try values.decode(String.self, forKey: .network))
        case .platformRule:
            let values = try container.nestedContainer(keyedBy: PlatformRuleCodingKeys.self, forKey: key)
            self = .platformRule(try values.decode(String.self, forKey: ._0))
        case .override:
            let values = try container.nestedContainer(keyedBy: OverrideCodingKeys.self, forKey: key)
            self = .override(note: try values.decode(String.self, forKey: .note))
        case .adjusted:
            let values = try container.nestedContainer(keyedBy: AdjustedCodingKeys.self, forKey: key)
            let base = (try? values.decode(String.self, forKey: .base)).map(Self.init(baseLabel:))
            self = .adjusted(base: try base ?? values.decode(ReleaseSource.self, forKey: .base),
                             offsetMinutes: try values.decode(Int.self, forKey: .offsetMinutes))
        case .anilist:
            self = .anilist
        case .dateOnly:
            self = .dateOnly
        }
    }

    /// The source an old `baseLabel` came from: "JP broadcast" is AniList's time, "Netflix rule" a platform rule.
    /// Any other label was a network (or an override's note, which Show detail words the same: "listed time").
    private init(baseLabel label: String) {
        self = switch label {
        case Self.anilist.baseLabel: .anilist
        case Self.dateOnly.baseLabel: .dateOnly
        case _ where label.hasSuffix(" rule"): .platformRule(label)
        default: .broadcast(network: label)
        }
    }
}

