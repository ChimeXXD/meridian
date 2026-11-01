import Foundation
import WidgetKit

/// Hands Upcoming to the widgets (D-05, D4-1): after every refresh, and so after every follow and unfollow (the
/// followed list changing triggers one), it writes the `DropSnapshot` to the App Group, saves a small poster per show,
/// and reloads the widget timelines. The container, the poster download and the reload are injected, so tests use a
/// temporary folder.
@MainActor
struct WidgetSnapshotWriter {
    /// A small JPEG for the widget from a poster URL, or nil when it can't be had.
    typealias FetchArt = @Sendable (URL) async -> Data?

    /// Nil when the App Group isn't granted: nothing is written, and the app still works.
    let container: URL?
    let fetchArt: FetchArt
    let reload: @MainActor () -> Void

    /// The real App Group, the app's artwork cache and WidgetKit.
    static var appGroup: WidgetSnapshotWriter {
        WidgetSnapshotWriter(container: SnapshotStore.container, fetchArt: WidgetArt.fetch,
                             reload: { WidgetCenter.shared.reloadAllTimelines() })
    }

    /// What the widgets get: every drop still worth showing, soonest first (one more than an hour past its time is
    /// gone, as on Upcoming), and the soonest listed date for the empty state ("Silo returns Fri 9 Jul 2027"), as
    /// Upcoming's own empty headline picks it.
    nonisolated static func snapshot(of drops: [Drop], now: Date) -> DropSnapshot {
        let kept = drops.filter { UpcomingSections.bucket($0, now: now) != .gone }
            .sorted { ($0.date, $0.id) < ($1.date, $1.id) }
        let nextReturn = kept.first { $0.confidence == .dateOnly && $0.airdate != nil }
        return DropSnapshot(generatedAt: now, drops: kept, nextReturn: nextReturn)
    }

    /// The snapshot the widgets have now, so a launch that can't reach the network keeps it instead of wiping it.
    func lastWritten() -> DropSnapshot? {
        container.flatMap { SnapshotStore.read(from: $0) }
    }

    /// Writes the snapshot for these drops and reloads the timelines. Returns what was written, or nil if nothing was.
    @discardableResult
    func write(_ drops: [Drop], now: Date) -> DropSnapshot? {
        guard let container else { return nil }
        let snapshot = Self.snapshot(of: drops, now: now)
        do {
            try SnapshotStore.write(snapshot, to: container)
        } catch {
            return nil
        }
        reload()
        return snapshot
    }

    /// Saves two images for each show in the snapshot, where missing: the hero art (`ShowArtwork.widget`, the wide key
    /// art or the poster) and the rows' small poster (`ShowArtwork.widgetPoster`). Deletes any other file, so art for
    /// shows no longer in the snapshot goes. Reloads the timelines once if anything changed.
    func saveArt(for snapshot: DropSnapshot, artwork: [String: ShowArtwork]) async {
        guard let container else { return }
        let files = FileManager.default
        let directory = SnapshotStore.artworkDirectory(in: container)
        try? files.createDirectory(at: directory, withIntermediateDirectories: true)
        let showIDs = Set(snapshot.drops.map(\.showID) + [snapshot.nextReturn?.showID].compactMap { $0 })
        let keep = Set(showIDs.flatMap { id in
            [SnapshotStore.artworkURL(showID: id, in: container), SnapshotStore.posterURL(showID: id, in: container)]
                .map(\.lastPathComponent)
        })
        var changed = false
        for file in (try? files.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        where !keep.contains(file.lastPathComponent) {
            if (try? files.removeItem(at: file)) != nil { changed = true }
        }
        // A show with only a thumbnail uses the same link for both images; fetch it once.
        var fetched: [URL: Data?] = [:]
        for id in showIDs.sorted() {
            let images = [(SnapshotStore.artworkURL(showID: id, in: container), artwork[id]?.widget),
                          (SnapshotStore.posterURL(showID: id, in: container), artwork[id]?.widgetPoster)]
            for case let (destination, source?) in images where !files.fileExists(atPath: destination.path) {
                if fetched[source] == nil { fetched[source] = .some(await fetchArt(source)) }
                guard let data = fetched[source] ?? nil else { continue }
                if (try? data.write(to: destination,
                                    options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])) != nil {
                    changed = true
                }
            }
        }
        if changed { reload() }
    }
}
