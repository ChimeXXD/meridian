#if DEBUG
import SwiftUI

/// Three ways to say how sure a time is without a colour code (Chime: the dots needed explaining, so users won't get
/// them). Launch with `trustA`, `trustB` or `trustC` after `-designPreview A`; the default is A.
enum TrustStyle: String, CaseIterable {
    /// The certainty is in the sentence itself: "Out today at…", "Expected Mon at…", "Airs in Japan…".
    case inWords = "trustA"
    /// Exact times carry nothing; only the exceptions get a word: "Estimated", "Time not announced".
    case flagged = "trustB"
    /// Every row names its source in plain words: "TV schedule", "Usual release time", "Japanese TV time".
    case sourced = "trustC"

    /// Read once: it is the default argument of every out line and meta line, re-evaluated on each minute tick.
    static let launched: TrustStyle =
        ProcessInfo.processInfo.arguments.lazy.compactMap(TrustStyle.init(rawValue:)).first ?? .inWords
}

extension DirectionCopy {
    /// The verb for style A: a sure time is "Out", a rule's estimate is "Expected", an anime's time is its airing in
    /// Japan.
    static func verb(_ drop: Drop) -> String {
        if case .anilist = drop.source { return "Airs in Japan" }
        return drop.confidence == .exact ? "Out" : "Expected"
    }

    /// Style B's flag: nothing for an exact time.
    static func flag(_ drop: Drop) -> String? {
        switch (drop.source, drop.confidence) {
        case (.dateOnly, _), (_, .dateOnly): "Time not announced"
        case (.adjusted, _): "Adjusted"
        case (_, .estimated): "Estimated"
        default: nil
        }
    }

    /// Style C's source, in words, after the episode and provider.
    static func sourcePhrase(_ drop: Drop) -> String {
        switch drop.source {
        case .broadcast: "TV schedule"
        case .platformRule: "Usual release time"
        case .override: drop.confidence == .exact ? "Confirmed time" : "Reported time"
        case .adjusted: "Adjusted by you"
        case .anilist: "Japanese TV time"
        case .dateOnly: "Date only"
        }
    }

    /// Show detail's one sentence on where the time came from, for every style.
    static func why(_ drop: Drop, zone: String?, formatter: DropFormatter) -> String {
        switch drop.source {
        case .broadcast(let network):
            guard let broadcast = timeFacts(drop, zone: zone, formatter: formatter).first?.value else {
                return "\(network) airs it at this time."
            }
            return "That's when \(network) airs it in its home zone: \(broadcast) time."
        case .platformRule(let rule):
            let platform = rule.replacingOccurrences(of: " rule", with: "")
            return "\(platform) doesn't publish release times, so this is when its new episodes usually arrive."
        case .override:
            return drop.confidence == .exact
                ? "This time was checked and confirmed."
                : "This time was reported but isn't confirmed yet."
        case .adjusted(let base, let minutes):
            let direction = minutes < 0 ? "taken off" : "added to"
            return "Your \(abs(minutes))-minute adjustment is \(direction) the \(base) time."
        case .anilist:
            return "This is when it airs on Japanese TV. Streaming services may add it a little later."
        case .dateOnly:
            return "Only the date is announced. The countdown starts once there's a time."
        }
    }
}
#endif
