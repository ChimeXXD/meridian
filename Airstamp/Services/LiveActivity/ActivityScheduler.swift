import Foundation
import Observation

/// Keeps the release-night Live Activities in step with Upcoming (SPEC §6, D-10, D-24). `RootView` calls `sync`
/// each time the app becomes active, after Upcoming refreshes; requests are only allowed in the foreground
/// (CLAUDE.md rule 6). Each sync:
/// 1. moves an activity to its drop's new time when a refresh moved it, keeping the old one as `delayedFrom`;
/// 2. ends activities whose drop was more than an hour ago (the system would keep them up to 8 hours), and ones not
///    yet out whose show's Live Activity switch was turned off;
/// 3. marks running activities whose drop has passed as `.outNow` (their stale date already shows "Out now");
/// 4. requests the new ones `ActivityPlanner` picks, at most 3 pending in all.
/// Settings reads `activitiesEnabled` for its permission line.
@MainActor
@Observable
final class ActivityScheduler {
    /// What one sync did, for Settings and the Debug menu.
    struct Outcome: Equatable, Sendable {
        /// False when Live Activities are switched off (nothing was requested) or a request was refused for it.
        var enabled: Bool
        /// The drop IDs of each activity requested.
        var requested: [[String]] = []
        /// Groups left out because 3 activities were already pending.
        var skippedOverLimit: [[String]] = []
        /// Groups whose request failed.
        var failed: [[String]] = []
        /// IDs of activities ended because their drop was more than an hour ago, or their show's switch went off.
        var ended: [String] = []
        /// IDs of activities moved to "Out now".
        var markedOut: [String] = []
    }

    /// An activity is ended this long after its drop (SPEC §6 Staleness).
    static let endAfter: TimeInterval = 3_600

    /// Whether Live Activities are switched on for Airstamp, as of the last sync or `refreshPermission`.
    private(set) var activitiesEnabled: Bool
    private(set) var lastOutcome: Outcome?

    let requester: any ActivityRequester
    /// The zone for the alert's time; nil uses the device's zone at each sync.
    private let formatter: DropFormatter?

    init(requester: any ActivityRequester = SystemActivityRequester(), formatter: DropFormatter? = nil) {
        self.requester = requester
        self.formatter = formatter
        activitiesEnabled = requester.areActivitiesEnabled
    }

    func refreshPermission() {
        activitiesEnabled = requester.areActivitiesEnabled
    }

    /// Ends expired activities, moves running ones to their drop's new time when a refresh moved it, marks passed
    /// ones out, and requests new ones for `drops` of the `optedIn` shows (`Drop.showID`: "38052", "anilist:154587").
    /// An activity not yet at its drop whose shows are all in `optedOut` (the switch turned off after it was
    /// scheduled) is ended. Call only while the app is in the foreground.
    @discardableResult
    func sync(drops: [Drop], optedIn: Set<String>, optedOut: Set<String> = [], leadMinutes: Int,
              now: Date = .now) async -> Outcome {
        var outcome = Outcome(enabled: requester.areActivitiesEnabled)
        let byID = Dictionary(drops.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for activity in requester.current() {
            var state = activity.state
            // The planner skips a drop an activity already covers, so a moved time only reaches it here.
            if let drop = activity.dropIDs.first.flatMap({ byID[$0] }), drop.confidence != .dateOnly,
               drop.date != state.dropDate {
                state = DropActivityAttributes.ContentState(phase: .upcoming, dropDate: drop.date,
                                                            delayedFrom: state.delayedFrom ?? state.dropDate)
            }
            let switchedOff = state.dropDate > now && !activity.dropIDs.isEmpty
                && activity.dropIDs.allSatisfy { byID[$0].map { optedOut.contains($0.showID) } ?? false }
            if state.dropDate.addingTimeInterval(Self.endAfter) < now || switchedOff {
                await requester.end(id: activity.id)
                outcome.ended.append(activity.id)
                continue
            }
            if state.dropDate <= now, state.phase != .outNow {
                state.phase = .outNow
                outcome.markedOut.append(activity.id)
            }
            if state != activity.state { await requester.update(id: activity.id, state: state) }
        }
        guard outcome.enabled else { return finish(outcome) }

        // Read again after the awaits: another sync may have requested in the meantime. From here to the end
        // nothing suspends, so two syncs can't both request the same drop.
        let ended = Set(outcome.ended)
        let existing = requester.current().filter {
            !ended.contains($0.id) && $0.dropDate.addingTimeInterval(Self.endAfter) >= now
        }
        let plan = ActivityPlanner.plan(drops: drops, optedIn: optedIn, leadMinutes: leadMinutes, now: now,
                                        existing: existing)
        outcome.skippedOverLimit = plan.skippedOverLimit
        let formatter = formatter ?? DropFormatter()
        for (index, planned) in plan.requests.enumerated() {
            let text = LiveActivityText.alert(planned.attributes, leadMinutes: planned.leadMinutes,
                                              dropDate: planned.state.dropDate, formatter: formatter)
            do throws(ActivityRequestError) {
                try requester.request(planned.attributes, state: planned.state,
                                      alert: ActivityAlert(title: text.title, body: text.body), start: planned.start)
                outcome.requested.append(planned.attributes.dropIDs)
            } catch {
                if case .failed = error {
                    // This one failed; the next may not.
                    outcome.failed.append(planned.attributes.dropIDs)
                    continue
                }
                // Switched off (`notAllowed`) or the system's limit (`tooMany`): the rest would fail the same way.
                if error == .notAllowed { outcome.enabled = false }
                outcome.failed += plan.requests[index...].map(\.attributes.dropIDs)
                break
            }
        }
        return finish(outcome)
    }

    private func finish(_ outcome: Outcome) -> Outcome {
        activitiesEnabled = outcome.enabled
        lastOutcome = outcome
        return outcome
    }
}
