import Foundation

/// The App Group file the app writes and the widgets read (D-05, SPEC §5): `snapshot.json` with every followed show's
/// next drop, plus a small art file per show under `Artwork/`, because widgets can't download.
///
/// Day 4 contract: these signatures are fixed so the widget views (D4-3, D4-4) and the store (D4-1) can be built at
/// once. The bodies are placeholders until D4-1 fills them in.
enum SnapshotStore {
    /// The shared container, or nil when the App Group entitlement is missing (free signing must grant it, Day 0).
    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
    }

    /// Writes the snapshot atomically to `<container>/snapshot.json`.
    static func write(_ snapshot: DropSnapshot, to container: URL) throws {}

    /// The last snapshot the app wrote; nil when there is none or it can't be read.
    static func read(from container: URL) -> DropSnapshot? { nil }

    /// Where a show's small widget art lives: `<container>/Artwork/<showID with ':' as '-'>.jpg`. It may not exist.
    static func artworkURL(showID: String, in container: URL) -> URL {
        container.appendingPathComponent("Artwork", isDirectory: true)
            .appendingPathComponent(showID.replacingOccurrences(of: ":", with: "-") + ".jpg")
    }
}
