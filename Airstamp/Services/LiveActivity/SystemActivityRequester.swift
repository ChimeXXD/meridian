import ActivityKit
import Foundation

/// The real `ActivityRequester`: ActivityKit's scheduled Live Activities (iOS 26, SPEC §6, D-24).
///
/// - Requests use `request(attributes:content:pushType:style:alertConfiguration:start:)`, never the deprecated
///   `startDate:` variant (CLAUDE.md rule 6). Scheduled requests require an `AlertConfiguration`.
/// - Every content's `staleDate` is the drop, so the views show "Out now" at the drop without the app running.
/// - `ActivityAuthorizationError` and any other error become an `ActivityRequestError`; nothing here can crash.
@MainActor
struct SystemActivityRequester: ActivityRequester {
    var areActivitiesEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func current() -> [RunningActivity] {
        Activity<DropActivityAttributes>.activities
            .filter { [.pending, .active, .stale].contains($0.activityState) }
            .map { RunningActivity(id: $0.id, dropIDs: $0.attributes.dropIDs, state: $0.content.state) }
    }

    @discardableResult
    func request(_ attributes: DropActivityAttributes, state: DropActivityAttributes.ContentState,
                 alert: ActivityAlert, start: Date) throws(ActivityRequestError) -> String {
        let content = ActivityContent(state: state, staleDate: state.dropDate)
        let configuration = AlertConfiguration(title: "\(alert.title)", body: "\(alert.body)", sound: .default)
        do {
            return try Activity<DropActivityAttributes>.request(attributes: attributes, content: content, pushType: nil,
                                                                style: .standard, alertConfiguration: configuration,
                                                                start: start).id
        } catch let error as ActivityAuthorizationError {
            throw Self.mapped(error)
        } catch {
            throw ActivityRequestError.failed(error.localizedDescription)
        }
    }

    func update(id: String, state: DropActivityAttributes.ContentState) async {
        guard let activity = Self.activity(id: id) else { return }
        await activity.update(ActivityContent(state: state, staleDate: state.dropDate))
    }

    func end(id: String) async {
        guard let activity = Self.activity(id: id) else { return }
        let final = ActivityContent(state: activity.content.state, staleDate: nil)
        await activity.end(final, dismissalPolicy: .immediate)
    }

    nonisolated private static func activity(id: String) -> Activity<DropActivityAttributes>? {
        Activity<DropActivityAttributes>.activities.first { $0.id == id }
    }

    private static func mapped(_ error: ActivityAuthorizationError) -> ActivityRequestError {
        switch error {
        case .denied, .unentitled, .unsupported, .unsupportedTarget: .notAllowed
        case .globalMaximumExceeded, .targetMaximumExceeded: .tooMany
        default: .failed(error.localizedDescription)
        }
    }
}
