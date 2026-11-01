#if DEBUG
import Foundation

extension ActivityScheduler {
    /// Debug → "Simulate delay +1 h" (SPEC §7): moves every running activity's drop later, keeping the first listed
    /// time as `delayedFrom` (shown struck through). The requester moves the stale date with the drop. Returns how
    /// many were moved.
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
}
#endif
