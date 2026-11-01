import WidgetKit

extension WidgetMoment: TimelineEntry {}

/// Reads the snapshot the app wrote to the App Group (D-05) and hands WidgetKit the timeline `WidgetTimeline` builds:
/// 5-minute spacing, "Out now" at each drop and the next drop an hour later, reload `.after(nextDrop)` (SPEC §5).
struct NextDropProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetMoment {
        WidgetSamples.moment(.countdown, now: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetMoment) -> Void) {
        let moment = WidgetTimeline.make(snapshot: Self.snapshot(), now: .now).entries.first
        // The widget gallery shows a sample until the app has written something to count down to.
        if context.isPreview, moment?.state ?? .nothing == .nothing {
            completion(placeholder(in: context))
        } else {
            completion(moment ?? placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetMoment>) -> Void) {
        let timeline = WidgetTimeline.make(snapshot: Self.snapshot(), now: .now)
        completion(Timeline(entries: timeline.entries, policy: timeline.reloadDate.map { .after($0) } ?? .never))
    }

    private static func snapshot() -> DropSnapshot? {
        SnapshotStore.container.flatMap { SnapshotStore.read(from: $0) }
    }
}
