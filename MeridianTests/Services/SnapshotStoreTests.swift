import CoreGraphics
import Foundation
import ImageIO
import SwiftData
import Testing
@testable import Meridian

/// The widgets can't read SwiftData or download, so the app hands them a JSON snapshot and a small poster per show in
/// the App Group (D-05, D4-1). It is rewritten after every follow, unfollow and refresh, then timelines reload.
@Suite("Snapshot store")
@MainActor
struct SnapshotStoreTests {
    /// Fri 30 Oct 2026, 18:00 in Lagos.
    static let now = Date(iso: "2026-10-30T17:00:00Z")

    static func container() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("snapshot-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func drop(_ id: String, show: String, at date: Date, _ confidence: Confidence = .exact,
                     airdate: String? = nil) -> Drop {
        Drop(id: "tvmaze:\(show):\(id)", showID: show, showName: "Show \(show)", season: 1, number: 2,
             episodeTitle: "Title", date: date, airdate: airdate, confidence: confidence,
             source: confidence == .dateOnly ? .dateOnly : .broadcast(network: "HBO"),
             provider: ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: true), previousDate: nil,
             broadcastZone: "America/New_York")
    }

    /// Counts timeline reloads and records which posters were fetched.
    final class Probe: @unchecked Sendable {
        private let lock = NSLock()
        private var _reloads = 0
        private var _fetched: [URL] = []
        var reloads: Int { lock.withLock { _reloads } }
        var fetched: [URL] { lock.withLock { _fetched } }
        func reload() { lock.withLock { _reloads += 1 } }
        func fetch(_ url: URL) { lock.withLock { _fetched.append(url) } }
    }

    nonisolated static let art = Data("small jpeg".utf8)

    static func writer(_ container: URL, _ probe: Probe) -> WidgetSnapshotWriter {
        WidgetSnapshotWriter(container: container, fetchArt: { url in probe.fetch(url); return art },
                             reload: { probe.reload() })
    }

    // MARK: The file

    @Test("a snapshot round-trips through <container>/snapshot.json")
    func roundTrip() throws {
        let container = try Self.container()
        let snapshot = DropSnapshot(generatedAt: Self.now,
                                    drops: [Self.drop("1", show: "1", at: Self.now.addingTimeInterval(3_600))],
                                    nextReturn: Self.drop("2", show: "2", at: Self.now, .dateOnly, airdate: "2027-07-09"))
        try SnapshotStore.write(snapshot, to: container)
        #expect(FileManager.default.fileExists(atPath: container.appendingPathComponent("snapshot.json").path))
        #expect(SnapshotStore.read(from: container) == snapshot)
    }

    @Test("dates are ISO 8601 UTC in the file and keep their milliseconds both ways")
    func dateEncoding() throws {
        let container = try Self.container()
        let precise = Self.now.addingTimeInterval(0.25)
        try SnapshotStore.write(DropSnapshot(generatedAt: precise, drops: [], nextReturn: nil), to: container)
        let text = try String(contentsOf: container.appendingPathComponent("snapshot.json"), encoding: .utf8)
        #expect(text.contains("2026-10-30T17:00:00.250Z"))
        let read = try #require(SnapshotStore.read(from: container))
        #expect(abs(read.generatedAt.timeIntervalSince(precise)) < 0.001)
    }

    @Test("a second write replaces the first")
    func overwrite() throws {
        let container = try Self.container()
        try SnapshotStore.write(DropSnapshot(generatedAt: Self.now, drops: [Self.drop("1", show: "1", at: Self.now)],
                                             nextReturn: nil), to: container)
        try SnapshotStore.write(DropSnapshot(generatedAt: Self.now, drops: [], nextReturn: nil), to: container)
        #expect(SnapshotStore.read(from: container)?.drops.isEmpty == true)
    }

    @Test("followed shows with nothing scheduled ride along, and a snapshot written before them still reads")
    func nothingScheduled() throws {
        let container = try Self.container()
        let quiet = QuietShow(showID: "anilist:151807", name: "Solo Leveling", status: "FINISHED", lastAired: "2025-03-29")
        let snapshot = WidgetSnapshotWriter.snapshot(of: [], nothingScheduled: [quiet], now: Self.now)
        #expect(snapshot.nothingScheduled == [quiet])
        try SnapshotStore.write(snapshot, to: container)
        #expect(SnapshotStore.read(from: container) == snapshot)
        let older = #"{"drops":[],"generatedAt":"2026-10-30T17:00:00.000Z"}"#
        try Data(older.utf8).write(to: container.appendingPathComponent("snapshot.json"))
        #expect(SnapshotStore.read(from: container)?.nothingScheduled == [])
    }

    @Test("no file or a broken file reads as nil, never a crash")
    func missingOrBroken() throws {
        let container = try Self.container()
        #expect(SnapshotStore.read(from: container) == nil)
        try Data("{not json".utf8).write(to: container.appendingPathComponent("snapshot.json"))
        #expect(SnapshotStore.read(from: container) == nil)
    }

    @Test("widget art lives under Artwork/ as v2 (wide key art), with ':' in an AniList ID made file-safe")
    func artworkPath() throws {
        let container = try Self.container()
        #expect(SnapshotStore.artworkURL(showID: "38052", in: container)
            == container.appendingPathComponent("Artwork/38052.v2.jpg"))
        #expect(SnapshotStore.artworkURL(showID: "anilist:154587", in: container).lastPathComponent
            == "anilist-154587.v2.jpg")
        #expect(SnapshotStore.posterURL(showID: "anilist:154587", in: container)
            == container.appendingPathComponent("Artwork/anilist-154587.poster.jpg"))
    }

    // MARK: What goes in it

    @Test("drops are soonest first, long-gone ones dropped, and nextReturn is the next listed date")
    func contents() {
        let later = Self.drop("later", show: "1", at: Self.now.addingTimeInterval(5 * 86_400))
        let gone = Self.drop("gone", show: "2", at: Self.now.addingTimeInterval(-2 * 3_600))
        let outNow = Self.drop("out", show: "3", at: Self.now.addingTimeInterval(-600))
        let farDate = Self.drop("far", show: "4", at: Date(iso: "2027-07-09T12:00:00Z"), .dateOnly, airdate: "2027-07-09")
        let nearDate = Self.drop("near", show: "5", at: Date(iso: "2026-12-01T12:00:00Z"), .dateOnly, airdate: "2026-12-01")
        let snapshot = WidgetSnapshotWriter.snapshot(of: [farDate, later, gone, nearDate, outNow], now: Self.now)
        #expect(snapshot.generatedAt == Self.now)
        #expect(snapshot.drops.map(\.id) == [outNow.id, later.id, nearDate.id, farDate.id])
        #expect(snapshot.nextReturn == nearDate)
        #expect(WidgetSnapshotWriter.snapshot(of: [later], now: Self.now).nextReturn == nil)
    }

    // MARK: Art

    @Test("art is saved for new shows, kept for current ones, and removed for shows no longer in the snapshot")
    func staleArtRemoved() async throws {
        let container = try Self.container()
        let artwork = container.appendingPathComponent("Artwork", isDirectory: true)
        try FileManager.default.createDirectory(at: artwork, withIntermediateDirectories: true)
        try Data("old".utf8).write(to: SnapshotStore.artworkURL(showID: "anilist:9", in: container))
        try Data("kept".utf8).write(to: SnapshotStore.artworkURL(showID: "1", in: container))
        // Poster art saved before v2 goes, so the show gets its wide art.
        let legacy = artwork.appendingPathComponent("1.jpg")
        try Data("poster".utf8).write(to: legacy)
        let probe = Probe()
        let snapshot = WidgetSnapshotWriter.snapshot(of: [Self.drop("a", show: "1", at: Self.now.addingTimeInterval(60)),
                                                          Self.drop("b", show: "anilist:2", at: Self.now.addingTimeInterval(90)),
                                                          Self.drop("c", show: "3", at: Self.now.addingTimeInterval(120)),
                                                          Self.drop("d", show: "4", at: Self.now.addingTimeInterval(150))],
                                                     now: Self.now)
        let url = { (name: String) in URL(string: "https://example.com/\(name).jpg")! }
        await Self.writer(container, probe).saveArt(for: snapshot, artwork: [
            "1": ShowArtwork(posterThumbnail: url("one")),
            "anilist:2": ShowArtwork(poster: url("big"), posterThumbnail: url("medium")),
            "3": ShowArtwork(background: url("background"), posterThumbnail: url("three")),
            "4": ShowArtwork(posterThumbnail: url("four")),
        ])
        #expect(!FileManager.default.fileExists(atPath: SnapshotStore.artworkURL(showID: "anilist:9", in: container).path))
        #expect(!FileManager.default.fileExists(atPath: legacy.path))
        #expect(try Data(contentsOf: SnapshotStore.artworkURL(showID: "1", in: container)) == Data("kept".utf8))
        #expect(try Data(contentsOf: SnapshotStore.artworkURL(showID: "anilist:2", in: container)) == Self.art)
        #expect(try Data(contentsOf: SnapshotStore.posterURL(showID: "anilist:2", in: container)) == Self.art)
        #expect(try Data(contentsOf: SnapshotStore.posterURL(showID: "4", in: container)) == Self.art)
        // Per show, the wide art then the small poster, each only when missing; one link used for both is fetched once.
        #expect(probe.fetched == [url("one"), url("background"), url("three"), url("four"), url("big"), url("medium")],
                "the wide key art (else the full poster) and the poster thumbnail, only where missing")
        #expect(probe.reloads == 1, "new art reloads the timelines so it shows")
    }

    @Test("a show with nothing scheduled gets only its small poster, for its row")
    func quietPosterOnly() async throws {
        let container = try Self.container()
        let probe = Probe()
        let snapshot = WidgetSnapshotWriter.snapshot(
            of: [], nothingScheduled: [QuietShow(showID: "9", name: "From", status: "Running", lastAired: nil)],
            now: Self.now)
        let thumbnail = URL(string: "https://example.com/from.jpg")!
        await Self.writer(container, probe).saveArt(for: snapshot, artwork: [
            "9": ShowArtwork(background: URL(string: "https://example.com/wide.jpg")!, posterThumbnail: thumbnail),
        ])
        #expect(probe.fetched == [thumbnail])
        #expect(FileManager.default.fileExists(atPath: SnapshotStore.posterURL(showID: "9", in: container).path))
        #expect(!FileManager.default.fileExists(atPath: SnapshotStore.artworkURL(showID: "9", in: container).path))
    }

    @Test("widget art is a JPEG at most 1000 px on its long side and under 100 KB, never upscaled")
    func smallJPEG() throws {
        let wide = try #require(WidgetArt.jpeg(Self.poster(width: 1_920, height: 1_080)))
        let wideSize = try Self.pixelSize(wide)
        #expect(wideSize == CGSize(width: 1_000, height: 563))
        #expect(wide.count < 100_000, "\(wide.count) bytes")
        let big = try #require(WidgetArt.jpeg(Self.poster(width: 1_000, height: 1_400)))
        let size = try Self.pixelSize(big)
        #expect(max(size.width, size.height) <= 1_000)
        #expect(size.width > 0 && size.height > size.width)
        #expect(big.count < 100_000, "\(big.count) bytes")
        let small = try #require(WidgetArt.jpeg(Self.poster(width: 210, height: 295)))
        #expect(try Self.pixelSize(small) == CGSize(width: 210, height: 295))
    }

    static func poster(width: Int, height: Int) -> CGImage {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        for band in 0..<20 {
            let t = CGFloat(band) / 20
            context.setFillColor(red: t, green: 0.4, blue: 1 - t, alpha: 1)
            context.fill(CGRect(x: 0, y: band * height / 20, width: width, height: height / 20 + 1))
        }
        return context.makeImage()!
    }

    static func pixelSize(_ data: Data) throws -> CGSize {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        #expect(CGImageSourceGetType(source) as String? == "public.jpeg")
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let width = try #require(properties[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(properties[kCGImagePropertyPixelHeight] as? Int)
        return CGSize(width: width, height: height)
    }

    // MARK: The app writes it

    static func model(_ container: URL, _ probe: Probe) throws -> UpcomingModel {
        let network = TVmazeClientTests.FakeNetwork([try TVmazeClientTests.ok("show-silo-embed"),
                                                     try TVmazeClientTests.ok("images-silo")])
        return UpcomingModel(client: TVmazeClientTests.client(network),
                             anilist: AniListClientTests.client(TVmazeClientTests.FakeNetwork([(500, [:], Data())])),
                             rules: try RulesStore.loadBundled(), viewerCountry: "NG",
                             snapshots: writer(container, probe),
                             // Its own defaults, so a test refresh doesn't stamp the app's "Updated" time (D6-2).
                             defaults: UserDefaults(suiteName: "snapshot-tests-\(UUID().uuidString)")!)
    }

    @Test("follow, refresh and unfollow each rewrite the snapshot and reload the widgets")
    func writtenAfterFollowRefreshUnfollow() async throws {
        let container = try Self.container()
        let probe = Probe()
        let model = try Self.model(container, probe)
        let follows = FollowStore(context: ModelContext(try FollowStoreTests.container()))

        // Nothing followed yet: an empty snapshot, so the widget says so.
        await model.refresh(try follows.shows(), now: Self.now)
        #expect(SnapshotStore.read(from: container)?.drops.isEmpty == true)
        let afterEmpty = probe.reloads
        #expect(afterEmpty >= 1)

        // Follow Silo: its date-only return is written, as the next real date too, with its wide key art.
        try follows.follow(FollowStoreTests.silo)
        await model.refresh(try follows.shows(), now: Self.now)
        let followed = try #require(SnapshotStore.read(from: container))
        #expect(followed.drops.map(\.showName) == ["Silo"])
        #expect(followed.nextReturn?.airdate == "2027-07-09")
        let art = SnapshotStore.artworkURL(showID: "38052", in: container)
        #expect(try Data(contentsOf: art) == Self.art)
        #expect(probe.fetched.map(\.lastPathComponent) == ["1151687.jpg", "1577677.jpg"],
                "Silo's TVmaze background for the hero, then its poster thumbnail for a row")
        #expect(probe.reloads > afterEmpty)

        // A plain refresh rewrites it again.
        let afterFollow = probe.reloads
        await model.refresh(try follows.shows(), now: Self.now.addingTimeInterval(60))
        #expect(SnapshotStore.read(from: container)?.generatedAt == Self.now.addingTimeInterval(60))
        #expect(probe.reloads > afterFollow)

        // Unfollow: the show and its art leave the App Group.
        try follows.unfollow(catalog: .tvmaze, id: 38052)
        await model.refresh(try follows.shows(), now: Self.now)
        let unfollowed = try #require(SnapshotStore.read(from: container))
        #expect(unfollowed.drops.isEmpty)
        #expect(unfollowed.nextReturn == nil)
        #expect(!FileManager.default.fileExists(atPath: art.path))
    }
}
