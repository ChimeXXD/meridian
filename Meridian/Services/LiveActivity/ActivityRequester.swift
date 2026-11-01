import Foundation

/// A release-night Live Activity that exists now (pending, active or stale; never an ended one).
struct RunningActivity: Equatable, Sendable {
    var id: String
    /// The drops it covers (`DropActivityAttributes.dropIDs`), soonest first.
    var dropIDs: [String]
    var state: DropActivityAttributes.ContentState

    var dropDate: Date { state.dropDate }
}

/// The alert shown when a scheduled activity starts (SPEC §6 "Silo starts in 2 hours · 02:00 · Apple TV").
struct ActivityAlert: Equatable, Sendable {
    var title: String
    var body: String
}

/// Why a request didn't go through, in the scheduler's terms rather than ActivityKit's.
enum ActivityRequestError: Error, Equatable, Sendable {
    /// Live Activities are switched off for Meridian, or not available on this device.
    case notAllowed
    /// The system's (unpublished) limit on activities is reached (D-24).
    case tooMany
    /// Anything else, with ActivityKit's description.
    case failed(String)
}

/// ActivityKit behind a protocol, so `ActivityScheduler` is tested with a fake (SPEC §6, ActivitySchedulerTests).
/// `SystemActivityRequester` is the real one. Requests must be made while the app is in the foreground
/// (CLAUDE.md rule 6).
@MainActor
protocol ActivityRequester {
    /// `ActivityAuthorizationInfo().areActivitiesEnabled`: false when the user switched them off.
    var areActivitiesEnabled: Bool { get }
    /// The activities that exist now.
    func current() -> [RunningActivity]
    /// Schedules an activity that appears at `start`, alerting with `alert`. Returns its ID.
    @discardableResult
    func request(_ attributes: DropActivityAttributes, state: DropActivityAttributes.ContentState,
                 alert: ActivityAlert, start: Date) throws(ActivityRequestError) -> String
    /// Replaces an activity's content; its stale date becomes the new drop time.
    func update(id: String, state: DropActivityAttributes.ContentState) async
    /// Ends an activity and removes it at once.
    func end(id: String) async
}
