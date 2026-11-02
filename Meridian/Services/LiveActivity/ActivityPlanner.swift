import Foundation

/// Decides which release-night Live Activities to request (SPEC §6, D-10, D-24). Pure: it reads drops and the
/// activities that already exist and returns what to ask ActivityKit for, so every rule is tested without it.
///
/// The rules:
/// - only shows the user left the Live Activity on for (`FollowedShow.liveActivity`);
/// - only drops still ahead and at most 7 days away, and never a `dateOnly` drop (it has no time to count down to);
/// - a drop already covered by an existing activity (it shares a drop ID) is skipped;
/// - same-night drops share one activity. **Same night** means a drop at most 3 hours after the first drop of its
///   group: drops are walked soonest first, and a drop more than 3 hours after the group's first starts a new group.
///   So 21:00, 22:30 and 23:55 merge, and a drop at 00:30 starts the next activity;
/// - at most 3 pending activities in all, counting the existing ones; the soonest groups win, the rest are skipped;
/// - an activity starts `lead` minutes before its drop, or now when that moment has already passed.
enum ActivityPlanner {
    /// How far ahead activities are scheduled (D-10).
    static let horizon: TimeInterval = 7 * 24 * 3_600
    /// Drops this close to their group's first drop share its activity.
    static let sameNightWindow: TimeInterval = 3 * 3_600
    /// Apple counts scheduled activities toward an unpublished limit (D-24).
    static let maxPending = 3

    /// One activity to request.
    struct Planned: Sendable {
        var attributes: DropActivityAttributes
        var state: DropActivityAttributes.ContentState
        /// When the activity appears: drop − lead, or now if that has passed.
        var start: Date
        /// The minutes from `start` to the drop, for the alert ("starts in 2 hours"). Less than the lead when the
        /// lead had already passed.
        var leadMinutes: Int
    }

    struct Plan: Sendable {
        var requests: [Planned] = []
        /// The drop IDs of each group left out because 3 activities are already pending, soonest first.
        var skippedOverLimit: [[String]] = []
    }

    static func plan(drops: [Drop], optedIn: Set<String>, leadMinutes: Int, now: Date,
                     existing: [RunningActivity]) -> Plan {
        let covered = Set(existing.flatMap(\.dropIDs))
        var seen = Set<String>()
        let candidates = drops
            .filter { drop in
                optedIn.contains(drop.showID) && drop.confidence != .dateOnly && !covered.contains(drop.id)
                    && drop.date > now && drop.date.timeIntervalSince(now) <= horizon
            }
            .sorted { ($0.date, $0.id) < ($1.date, $1.id) }
            .filter { seen.insert($0.id).inserted }
        let slots = max(0, maxPending - existing.count)
        var plan = Plan()
        for (index, group) in nights(candidates).enumerated() {
            if index < slots {
                plan.requests.append(planned(group, leadMinutes: leadMinutes, now: now))
            } else {
                plan.skippedOverLimit.append(group.map(\.id))
            }
        }
        return plan
    }

    /// Groups drops sorted soonest first into same-night groups (see the type's note).
    static func nights(_ sorted: [Drop]) -> [[Drop]] {
        var groups: [[Drop]] = []
        for drop in sorted {
            if let first = groups.last?.first, drop.date.timeIntervalSince(first.date) <= sameNightWindow {
                groups[groups.count - 1].append(drop)
            } else {
                groups.append([drop])
            }
        }
        return groups
    }

    /// The attributes for a non-empty group: the drop IDs soonest first, and the first drop's name, episode,
    /// provider (and whether it has no official stream here), verb and show (for its art). `start` is when the
    /// activity appears, so its ring and bar fill from there to the drop.
    static func attributes(for group: [Drop], start: Date? = nil) -> DropActivityAttributes {
        let first = group[0]
        return DropActivityAttributes(dropIDs: group.map(\.id), showName: first.showName,
                                      episodeLabel: first.episodeLabel ?? "", provider: first.provider?.display,
                                      verb: ReleaseWording.verb(first, past: false),
                                      noOfficialStream: first.provider?.noOfficialStream ?? false,
                                      showID: first.showID, windowStart: start)
    }

    /// `group` comes from `nights`, so it's never empty.
    private static func planned(_ group: [Drop], leadMinutes: Int, now: Date) -> Planned {
        let first = group[0]
        let start = max(first.date.addingTimeInterval(-Double(max(0, leadMinutes)) * 60), now)
        let minutes = max(1, Int((first.date.timeIntervalSince(start) / 60).rounded()))
        return Planned(attributes: attributes(for: group, start: start),
                       state: DropActivityAttributes.ContentState(phase: .upcoming, dropDate: first.date,
                                                                  delayedFrom: first.previousDate),
                       start: start, leadMinutes: minutes)
    }
}
