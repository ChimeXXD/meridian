import Foundation

/// The App Group file the app writes and the widgets read (D-05, SPEC §5): `snapshot.json` with every followed show's
/// next drop, plus a small art file per show under `Artwork/`, because widgets can't download.
///
/// Dates are ISO 8601 UTC with milliseconds ("2026-10-30T17:00:00.250Z") both ways, so the file reads plainly in the
/// Debug dump and the widgets decode exactly what the app encoded. Always go through `write` and `read`.
enum SnapshotStore {
    static let fileName = "snapshot.json"

    /// The shared container, or nil when the App Group entitlement is missing (free signing must grant it, Day 0).
    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
    }

    /// Writes the snapshot atomically to `<container>/snapshot.json`, so a widget never reads half a file. The file
    /// stays readable after the first unlock, because Lock Screen widgets render while the phone is locked.
    static func write(_ snapshot: DropSnapshot, to container: URL) throws {
        let data = try encoder.encode(snapshot)
        try data.write(to: container.appendingPathComponent(fileName),
                       options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    /// The last snapshot the app wrote; nil when there is none or it can't be read.
    static func read(from container: URL) -> DropSnapshot? {
        guard let data = try? Data(contentsOf: container.appendingPathComponent(fileName)) else { return nil }
        return try? decoder.decode(DropSnapshot.self, from: data)
    }

    /// Where a show's widget art lives: `<container>/Artwork/<showID with ':' as '-'>.v2.jpg`. It may not exist. v2 is
    /// the wide key art; the writer deletes any other file in the folder, so poster art saved before it is replaced.
    static func artworkURL(showID: String, in container: URL) -> URL {
        artworkDirectory(in: container)
            .appendingPathComponent(showID.replacingOccurrences(of: ":", with: "-") + ".v2.jpg")
    }

    /// Where a show's small poster for the widgets' rows lives: `<container>/Artwork/<showID>.poster.jpg`. It may not
    /// exist.
    static func posterURL(showID: String, in container: URL) -> URL {
        artworkDirectory(in: container)
            .appendingPathComponent(showID.replacingOccurrences(of: ":", with: "-") + ".poster.jpg")
    }

    static func artworkDirectory(in container: URL) -> URL {
        container.appendingPathComponent("Artwork", isDirectory: true)
    }

    private static let dateStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(dateStyle))
        }
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            // A whole-second stamp ("…17:00:00Z") is accepted too, in case one is written by hand for a test.
            if let date = (try? dateStyle.parse(text)) ?? (try? Date.ISO8601FormatStyle().parse(text)) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not an ISO 8601 date: \(text)")
        }
        return decoder
    }
}
