import Foundation

/// A later time for the same episode is a delay (SPEC core flow 5): each refresh keeps the first listed time as
/// `previousDate`, so the views can say "Delayed from 21:00" and the Live Activity moves with it. Only a sure time can
/// be delayed (D-58): an estimate replaced by another estimate or by a published time is our guess being refined, not
/// the show moving, and saying "Delayed" would claim more than we know (D-40).
enum DelayDetection {
    /// `fresh` in order, each carrying a delay from the matching episode in `previous` (the last known result).
    static func carry(from previous: [Drop], into fresh: [Drop]) -> [Drop] {
        let known = Dictionary(previous.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return fresh.map { drop in
            guard let old = known[drop.id], old.confidence == .exact, drop.confidence == .exact else { return drop }
            var drop = drop
            let listed = old.previousDate ?? old.date
            drop.previousDate = drop.date > listed ? listed : nil
            return drop
        }
    }
}
