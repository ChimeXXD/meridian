import Foundation
import Testing
@testable import Airstamp

/// D5-2: scheduling the release-night Live Activities (SPEC §6, D-10, D-24, CLAUDE.md rule 6), against a fake
/// ActivityKit. Monday 2 Nov 2026 12:00 UTC.
@MainActor
@Suite("Live Activity scheduler")
struct ActivitySchedulerTests {
    static let now = Date(iso: "2026-11-02T12:00:00Z")
    static let hour: TimeInterval = 3_600, minute: TimeInterval = 60, day: TimeInterval = 86_400

    static func drop(_ id: String, at date: Date, confidence: Confidence = .exact) -> Drop {
        Drop(id: "tvmaze:\(id):1", showID: id, showName: "Show \(id)", season: 2, number: 5, episodeTitle: nil,
             date: date, airdate: confidence == .dateOnly ? "2026-11-03" : nil, confidence: confidence,
             source: confidence == .exact ? .broadcast(network: "HBO") : confidence == .dateOnly
                 ? .dateOnly : .platformRule("Netflix rule"),
             provider: ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: false), previousDate: nil)
    }

    static func state(_ date: Date, phase: DropActivityAttributes.Phase = .upcoming)
        -> DropActivityAttributes.ContentState {
        DropActivityAttributes.ContentState(phase: phase, dropDate: date, delayedFrom: nil)
    }

    static func scheduler(_ requester: FakeActivityRequester) -> ActivityScheduler {
        ActivityScheduler(requester: requester, formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
    }

    /// Four drops on four nights.
    static let nights = (1...4).map { drop("\($0)", at: now.addingTimeInterval(Double($0) * day)) }
    static let everyShow: Set<String> = ["1", "2", "3", "4", "5", "6"]

    @Test("at most 3 pending: the 4th is skipped, soonest first, and existing activities count")
    func fourthSkipped() async {
        let requester = FakeActivityRequester()
        let outcome = await Self.scheduler(requester)
            .sync(drops: Self.nights.reversed(), optedIn: Self.everyShow, leadMinutes: 120, now: Self.now)

        #expect(requester.requests.map(\.attributes.dropIDs) == Self.nights.prefix(3).map { [$0.id] })
        #expect(outcome.requested.count == 3)
        #expect(outcome.skippedOverLimit == [[Self.nights[3].id]])

        let busy = FakeActivityRequester()
        busy.activities = [RunningActivity(id: "a", dropIDs: ["other"], state: Self.state(Self.now + 5 * Self.day)),
                           RunningActivity(id: "b", dropIDs: ["other2"], state: Self.state(Self.now + 6 * Self.day))]
        let plan = await Self.scheduler(busy)
            .sync(drops: Self.nights, optedIn: Self.everyShow, leadMinutes: 120, now: Self.now)
        #expect(plan.requested == [[Self.nights[0].id]])
        #expect(plan.skippedOverLimit.count == 3)
    }

    @Test("same-night drops (within 3 hours of the first) merge into one activity, soonest first")
    func sameNightMerged() async throws {
        let first = Self.now.addingTimeInterval(8 * Self.hour)
        let a = Self.drop("1", at: first)
        let b = Self.drop("2", at: first.addingTimeInterval(90 * Self.minute))
        let c = Self.drop("3", at: first.addingTimeInterval(3 * Self.hour))
        let d = Self.drop("4", at: first.addingTimeInterval(3 * Self.hour + Self.minute))
        let requester = FakeActivityRequester()
        await Self.scheduler(requester).sync(drops: [d, c, b, a], optedIn: Self.everyShow, leadMinutes: 120,
                                             now: Self.now)

        #expect(requester.requests.map(\.attributes.dropIDs) == [[a.id, b.id, c.id], [d.id]])
        let merged = try #require(requester.requests.first)
        #expect(merged.attributes.showName == "Show 1")
        #expect(merged.state == Self.state(first))
        #expect(merged.start == first.addingTimeInterval(-2 * Self.hour))
    }

    @Test("a drop already covered by an existing activity is skipped")
    func coveredSkipped() async {
        let a = Self.drop("1", at: Self.now.addingTimeInterval(Self.day))
        let b = Self.drop("2", at: Self.now.addingTimeInterval(2 * Self.day))
        let requester = FakeActivityRequester()
        requester.activities = [RunningActivity(id: "x", dropIDs: ["tvmaze:9:1", a.id], state: Self.state(a.date))]
        await Self.scheduler(requester).sync(drops: [a, b], optedIn: Self.everyShow, leadMinutes: 120, now: Self.now)

        #expect(requester.requests.map(\.attributes.dropIDs) == [[b.id]])
    }

    @Test("dateOnly, more than 7 days away, already out and opted-out drops are left out")
    func exclusions() async {
        let drops = [
            Self.drop("1", at: Self.now.addingTimeInterval(Self.day), confidence: .dateOnly),
            Self.drop("2", at: Self.now.addingTimeInterval(7 * Self.day + Self.minute)),
            Self.drop("3", at: Self.now.addingTimeInterval(-Self.minute)),
            Self.drop("4", at: Self.now.addingTimeInterval(Self.day)),
        ]
        let requester = FakeActivityRequester()
        await Self.scheduler(requester).sync(drops: drops, optedIn: ["1", "2", "3"], leadMinutes: 120, now: Self.now)
        #expect(requester.requests.isEmpty)

        // Exactly 7 days ahead is still in.
        let edge = Self.drop("5", at: Self.now.addingTimeInterval(7 * Self.day))
        await Self.scheduler(requester).sync(drops: [edge], optedIn: ["5"], leadMinutes: 120, now: Self.now)
        #expect(requester.requests.map(\.attributes.dropIDs) == [[edge.id]])
    }

    @Test("start is the drop minus the lead, or now once the lead has passed; the alert says the real lead")
    func startTimes() async {
        let later = Self.drop("1", at: Self.now.addingTimeInterval(2 * Self.day))
        let soon = Self.drop("2", at: Self.now.addingTimeInterval(45 * Self.minute))
        let plan = ActivityPlanner.plan(drops: [later, soon], optedIn: Self.everyShow, leadMinutes: 120,
                                        now: Self.now, existing: [])

        #expect(plan.requests.map(\.start) == [Self.now, later.date.addingTimeInterval(-120 * Self.minute)])
        #expect(plan.requests.map(\.leadMinutes) == [45, 120])
        // The ring and bar fill from the start to the drop; the views find the art by the first show's ID.
        #expect(plan.requests.map(\.attributes.windowStart) == plan.requests.map(\.start))
        #expect(plan.requests.map(\.attributes.showID) == ["2", "1"])
        #expect(plan.requests.map(\.state) == [Self.state(soon.date), Self.state(later.date)])
    }

    @Test("attributes: episode, provider with its country, and the certainty verb (D-20, D-40)")
    func attributes() {
        let exact = ActivityPlanner.attributes(for: [Self.drop("1", at: Self.now + Self.day)])
        #expect(exact.episodeLabel == "S2E5")
        #expect(exact.provider == "HBO · US")
        #expect(exact.verb == "Out")
        var bare = Self.drop("2", at: Self.now + Self.day, confidence: .estimated)
        bare.number = nil
        bare.provider = nil
        let estimate = ActivityPlanner.attributes(for: [bare])
        #expect(estimate.episodeLabel == "")
        #expect(estimate.provider == nil)
        #expect(estimate.verb == "Expected")
    }

    @Test("Live Activities switched off: no requests, and the outcome says so")
    func disabled() async {
        let requester = FakeActivityRequester()
        requester.areActivitiesEnabled = false
        let scheduler = Self.scheduler(requester)
        let outcome = await scheduler.sync(drops: Self.nights, optedIn: Self.everyShow, leadMinutes: 120, now: Self.now)

        #expect(requester.requests.isEmpty)
        #expect(outcome.enabled == false)
        #expect(scheduler.activitiesEnabled == false)
    }

    @Test("a refused request (denied) is caught: no crash, the rest aren't tried, the state says off")
    func denied() async {
        let requester = FakeActivityRequester()
        requester.error = .notAllowed
        let scheduler = Self.scheduler(requester)
        let outcome = await scheduler.sync(drops: Self.nights, optedIn: Self.everyShow, leadMinutes: 120, now: Self.now)

        #expect(requester.attempts == 1)
        #expect(outcome.requested.isEmpty)
        #expect(outcome.failed.count == 3)
        #expect(outcome.enabled == false)
        #expect(scheduler.activitiesEnabled == false)
    }

    @Test("endsExpired: an activity more than 1 hour past its drop is ended and frees its slot")
    func endsExpired() async {
        let requester = FakeActivityRequester()
        requester.activities = [
            RunningActivity(id: "old", dropIDs: ["o"], state: Self.state(Self.now - Self.hour - Self.minute, phase: .outNow)),
            RunningActivity(id: "b", dropIDs: ["b"], state: Self.state(Self.now + 5 * Self.day)),
            RunningActivity(id: "c", dropIDs: ["c"], state: Self.state(Self.now + 6 * Self.day)),
        ]
        let outcome = await Self.scheduler(requester)
            .sync(drops: Self.nights, optedIn: Self.everyShow, leadMinutes: 120, now: Self.now)

        #expect(requester.ended == ["old"])
        #expect(outcome.ended == ["old"])
        #expect(outcome.requested == [[Self.nights[0].id]])
    }

    @Test("a running activity whose drop has passed (within the hour) is updated to Out now, once")
    func passedMarkedOut() async throws {
        let requester = FakeActivityRequester()
        let dropDate = Self.now - 59 * Self.minute
        requester.activities = [RunningActivity(id: "a", dropIDs: ["a"], state: Self.state(dropDate)),
                                RunningActivity(id: "b", dropIDs: ["b"], state: Self.state(Self.now - 5 * Self.minute,
                                                                                          phase: .outNow))]
        let scheduler = Self.scheduler(requester)
        let outcome = await scheduler.sync(drops: [], optedIn: [], leadMinutes: 120, now: Self.now)

        #expect(requester.ended.isEmpty)
        #expect(outcome.markedOut == ["a"])
        let update = try #require(requester.updates.first)
        #expect(requester.updates.count == 1)
        #expect(update.id == "a" && update.state == Self.state(dropDate, phase: .outNow))
    }

    @Test("a refresh that moves a covered drop moves its activity, keeping the old time as delayedFrom")
    func movedDropUpdated() async throws {
        let listed = Self.now + Self.day
        var moved = Self.drop("1", at: listed + Self.hour)
        moved.previousDate = listed
        let requester = FakeActivityRequester()
        requester.activities = [RunningActivity(id: "a", dropIDs: [moved.id], state: Self.state(listed))]
        await Self.scheduler(requester).sync(drops: [moved], optedIn: Self.everyShow, leadMinutes: 120, now: Self.now)

        let update = try #require(requester.updates.first)
        #expect(requester.updates.count == 1)
        #expect(update.state == DropActivityAttributes.ContentState(phase: .upcoming, dropDate: moved.date,
                                                                   delayedFrom: listed))
        #expect(requester.requests.isEmpty)
    }

    @Test("switching a show's Live Activity off ends its pending activity, not one already out")
    func optedOutEnded() async {
        let ahead = Self.drop("1", at: Self.now + Self.day)
        let passed = Self.drop("2", at: Self.now - 10 * Self.minute)
        let requester = FakeActivityRequester()
        requester.activities = [RunningActivity(id: "a", dropIDs: [ahead.id], state: Self.state(ahead.date)),
                                RunningActivity(id: "b", dropIDs: [passed.id],
                                                state: Self.state(passed.date, phase: .outNow))]
        let outcome = await Self.scheduler(requester)
            .sync(drops: [ahead, passed], optedIn: [], optedOut: ["1", "2"], leadMinutes: 120, now: Self.now)

        #expect(outcome.ended == ["a"])
        #expect(requester.requests.isEmpty)
    }
}

/// ActivityKit stand-in: records requests, updates and ends, and keeps a list of "running" activities.
@MainActor
final class FakeActivityRequester: ActivityRequester {
    struct Request {
        var attributes: DropActivityAttributes
        var state: DropActivityAttributes.ContentState
        var alert: ActivityAlert
        var start: Date
    }

    var areActivitiesEnabled = true
    var activities: [RunningActivity] = []
    var error: ActivityRequestError?
    private(set) var attempts = 0
    private(set) var requests: [Request] = []
    private(set) var updates: [(id: String, state: DropActivityAttributes.ContentState)] = []
    private(set) var ended: [String] = []

    func current() -> [RunningActivity] { activities }

    @discardableResult
    func request(_ attributes: DropActivityAttributes, state: DropActivityAttributes.ContentState,
                 alert: ActivityAlert, start: Date) throws(ActivityRequestError) -> String {
        attempts += 1
        if let error { throw error }
        requests.append(Request(attributes: attributes, state: state, alert: alert, start: start))
        let id = "fake-\(requests.count)"
        activities.append(RunningActivity(id: id, dropIDs: attributes.dropIDs, state: state))
        return id
    }

    func update(id: String, state: DropActivityAttributes.ContentState) async {
        updates.append((id, state))
        if let index = activities.firstIndex(where: { $0.id == id }) { activities[index].state = state }
    }

    func end(id: String) async {
        ended.append(id)
        activities.removeAll { $0.id == id }
    }
}
