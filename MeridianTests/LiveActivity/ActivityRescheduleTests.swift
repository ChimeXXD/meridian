import Foundation
import Testing
@testable import Meridian

/// SPEC §6: "When a drop moves, its pending … activity is ended and a new one is scheduled for the new time." A booked
/// activity's start and alert are fixed when it's requested, so updating its content alone would still start it at
/// the old lead and announce the old time; one already on screen is moved in place (D-58).
@MainActor
@Suite("Live Activity rescheduling")
struct ActivityRescheduleTests {
    typealias Base = ActivitySchedulerTests

    @Test("reschedulesOnDelay: a booked activity that hasn't started is ended and booked again for the new time")
    func reschedulesOnDelay() async throws {
        let listed = Base.now + Base.day
        var moved = Base.drop("1", at: listed + 3 * Base.hour)
        moved.previousDate = listed
        let requester = FakeActivityRequester()
        requester.activities = [RunningActivity(id: "a", dropIDs: [moved.id], state: Base.state(listed),
                                                windowStart: listed - 2 * Base.hour)]
        let outcome = await Base.scheduler(requester)
            .sync(drops: [moved], optedIn: Base.everyShow, leadMinutes: 120, now: Base.now)

        #expect(requester.ended == ["a"] && outcome.ended == ["a"])
        #expect(requester.updates.isEmpty)
        let request = try #require(requester.requests.first)
        #expect(requester.requests.count == 1)
        #expect(request.start == moved.date - 2 * Base.hour)
        #expect(request.state == DropActivityAttributes.ContentState(phase: .upcoming, dropDate: moved.date,
                                                                    delayedFrom: listed))
        // The alert announces the new time: 16:00 in Lagos (15:00Z), not the listed 13:00.
        #expect(request.alert.body.contains("16:00") && !request.alert.body.contains("13:00"))
    }

    @Test("an activity already on screen is moved in place, not ended")
    func startedMovedInPlace() async throws {
        let listed = Base.now + Base.hour
        var moved = Base.drop("1", at: listed + Base.hour)
        moved.previousDate = listed
        let requester = FakeActivityRequester()
        requester.activities = [RunningActivity(id: "a", dropIDs: [moved.id], state: Base.state(listed),
                                                windowStart: Base.now - Base.hour)]
        await Base.scheduler(requester).sync(drops: [moved], optedIn: Base.everyShow, leadMinutes: 120, now: Base.now)

        #expect(requester.ended.isEmpty && requester.requests.isEmpty)
        let update = try #require(requester.updates.first)
        #expect(update.state.dropDate == moved.date && update.state.delayedFrom == listed)
    }

    @Test("a new lead time (Settings) books again the activities that haven't started; one on screen stays (audit #13)")
    func newLeadRebooks() async throws {
        let later = Base.drop("1", at: Base.now + Base.day)
        let soon = Base.drop("2", at: Base.now + Base.hour)
        let requester = FakeActivityRequester()
        requester.activities = [
            RunningActivity(id: "pending", dropIDs: [later.id], state: Base.state(later.date),
                            windowStart: later.date - 2 * Base.hour),
            RunningActivity(id: "showing", dropIDs: [soon.id], state: Base.state(soon.date),
                            windowStart: Base.now - Base.hour),
        ]
        await Base.scheduler(requester).sync(drops: [later, soon], optedIn: Base.everyShow, leadMinutes: 360,
                                             now: Base.now, rebookPending: true)

        #expect(requester.ended == ["pending"])
        let request = try #require(requester.requests.first)
        #expect(requester.requests.count == 1)
        #expect(request.start == later.date - 6 * Base.hour)
    }

    @Test("a new lead time with no drops loaded keeps the booked activities rather than ending them for good")
    func newLeadWithoutDropsKeeps() async {
        let later = Base.drop("1", at: Base.now + Base.day)
        let requester = FakeActivityRequester()
        requester.activities = [RunningActivity(id: "pending", dropIDs: [later.id], state: Base.state(later.date),
                                                windowStart: later.date - 2 * Base.hour)]
        await Base.scheduler(requester).sync(drops: [], optedIn: Base.everyShow, leadMinutes: 360,
                                             now: Base.now, rebookPending: true)

        #expect(requester.ended.isEmpty)
    }
}
