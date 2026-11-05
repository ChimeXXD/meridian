#if DEBUG
import Foundation

extension ActivityScheduler {
    /// Debug → "Simulate delay +1 h" (SPEC §7): moves every running activity's drop later, keeping the first listed
    /// time as `delayedFrom` (the views say "Delayed from 22:00"). The requester moves the stale date with the drop.
    /// Returns how many were moved.
    @discardableResult
    func delayAll(by interval: TimeInterval) async -> Int {
        let running = requester.current()
        for activity in running {
            let state = DropActivityAttributes.ContentState(phase: .upcoming,
                                                            dropDate: activity.dropDate.addingTimeInterval(interval),
                                                            delayedFrom: activity.state.delayedFrom ?? activity.dropDate)
            await requester.update(id: activity.id, state: state)
        }
        return running.count
    }

    /// Ends every activity booked for Debug's fake drops only, so a new demo take doesn't show an earlier one's
    /// activity too (RootView's sync never touches fakes). Real activities keep running. Returns how many ended.
    @discardableResult
    func endFakes() async -> Int {
        let fakes = requester.current().filter { !$0.dropIDs.isEmpty && $0.dropIDs.allSatisfy { DebugFakeDrop.isFake(id: $0) } }
        for activity in fakes { await requester.end(id: activity.id) }
        return fakes.count
    }
}
#endif
