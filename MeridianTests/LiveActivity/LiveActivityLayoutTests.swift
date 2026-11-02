import SwiftUI
import Testing
import UIKit
@testable import Meridian

/// SPEC acceptance and D5-1: the Lock Screen view is at most 160 pt tall at a 360 pt width with the longest show name,
/// in every state, with and without art, and the minimal view fits 28 pt when the island is limited in width. Every presentation is
/// rendered into `fidelity/shots/live-activity/` (git-ignored) for Chime to look at, as `WidgetRenderTests` does for
/// the widgets; the renders with art are cut by `ArtMatte` and listed in `art-holes.json`, so the design system fills
/// them with the show's real art. Timers read against the real clock, so the samples are built around `Date.now`.
@MainActor
@Suite("Live Activity layout")
struct LiveActivityLayoutTests {
    static let width: CGFloat = 360
    static let maxHeight: CGFloat = 160
    static let longestName = "The Lord of the Rings: The Rings of Power, Season Two Finale"
    static let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()

    /// Every state UI-BRIEF §6.2 lists, plus "Out now" reached through a stale context rather than the phase.
    enum Shot: String, CaseIterable {
        case countingDown, longName, merged, delayed, outNow, stale

        var sample: LiveActivitySamples.Case {
            switch self {
            case .countingDown, .stale: .countingDown
            case .longName: .longName
            case .merged: .merged
            case .delayed: .delayed
            case .outNow: .outNow
            }
        }
    }

    /// The sample with the longest name and a long provider, so nothing has more to fit.
    static func longest(_ sample: LiveActivitySamples.Case) -> DropActivityAttributes {
        var attributes = LiveActivitySamples.attributes(sample)
        attributes.showName = longestName
        attributes.episodeLabel = "S12E104"
        attributes.provider = "Paramount+ · US"
        return attributes
    }

    static var folder: URL { root.appendingPathComponent("fidelity/shots/live-activity", isDirectory: true) }

    /// A neutral placeholder, never real artwork (CLAUDE.md rule 9), in the 16:9 shape of the key art the App Group
    /// holds, for the Always-On check, which hides it.
    static let heroArt = placeholder(CGSize(width: 192, height: 108))

    static func placeholder(_ size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor(white: 0.55, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(white: 0.8, alpha: 1).setFill()
            context.fill(CGRect(x: size.width / 6, y: size.height / 6, width: size.width * 2 / 3,
                                height: size.height * 5 / 12))
        }
    }

    /// Each view is shot without art (the Debug show, or art not saved yet) and with art, which `ArtMatte` cuts out.
    static let artOptions: [(suffix: String, art: Bool)] = [("", false), ("-art", true)]

    /// The show the sample's art belongs to: its own name, even when the test swaps in the longest one.
    static func show(_ sample: LiveActivitySamples.Case) -> String { LiveActivitySamples.attributes(sample).showName }

    /// The island's poster marks and art, from `LiveActivityPosterMark` and `LiveActivityExpandedView`.
    static func mark(_ size: CGFloat, circle: Bool = false, show: String) -> ArtHoleExpectation {
        .patch(size: CGSize(width: size, height: size), radius: circle ? size / 2 : size / 4, circle: circle,
               show: show, kind: "poster")
    }

    /// The minimal view's poster, a circle inside its ring.
    static func ringMark(show: String) -> ArtHoleExpectation {
        mark(LiveActivityMinimalView.diameter - 2 * LiveActivityRing<EmptyView>.inset, circle: true, show: show)
    }

    /// Renders at 3x into the shots folder and returns the size in points. The island is pure black; the Lock Screen
    /// banner draws its own background. The ring and bar are drawn as shapes, since `ImageRenderer` can't draw the
    /// system's live progress views. With `holes`, the view is drawn with solid art and cut by `ArtMatte`, and its
    /// holes go into `art-holes.json`; without, it gets no art.
    @discardableResult
    static func shoot<V: View>(name: String, background: Color = .black, holes: [ArtHoleExpectation]? = nil,
                               _ view: (UIImage?) -> V) throws -> CGSize {
        func render(_ art: UIImage?) throws -> UIImage {
            let renderer = ImageRenderer(content: view(art)
                .background(background)
                .environment(\.colorScheme, .dark)
                .environment(\.liveActivityStaticProgress, true))
            renderer.scale = 3
            return try #require(renderer.uiImage, "\(name) didn't render")
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("\(name).png")
        guard let holes else {
            let image = try render(nil)
            try #require(image.pngData()).write(to: url)
            return image.size
        }
        let matte = try ArtMatte.cut(render)
        try ArtHoleManifest.record(matte.shot(holes, scale: 3, name: name), name: "\(name).png", in: folder)
        try matte.png.write(to: url)
        return CGSize(width: CGFloat(matte.width) / 3, height: CGFloat(matte.height) / 3)
    }

    @Test("the Lock Screen view is at most 160 pt tall with the longest name, in every state, with and without art",
          arguments: Shot.allCases)
    func lockScreenHeight(shot: Shot) throws {
        let now = Date.now
        let samples = [("", LiveActivitySamples.attributes(shot.sample, now: now)),
                       ("-longest", Self.longest(shot.sample))]
        // The key art on the right edge, full height, centred in its frame (`LiveActivityArtEdge`, which the Lock
        // Screen view draws at its default share).
        let share = LiveActivityArtEdge.defaultShare
        let edge = ArtHoleExpectation.frame(unit: CGRect(x: 1 - share, y: 0, width: share, height: 1), align: "center",
                                            show: Self.show(shot.sample), kind: "wide")
        for (suffix, attributes) in samples {
            for option in Self.artOptions {
                let name = "lock-\(shot.rawValue)\(suffix)\(option.suffix)"
                let size = try Self.shoot(name: name, holes: option.art ? [edge] : nil) { art in
                    LiveActivityLockScreenView(attributes: attributes,
                                               state: LiveActivitySamples.state(shot.sample, now: now),
                                               art: art, isStale: shot == .stale, now: now, formatter: Self.formatter)
                        .frame(width: Self.width)
                        .fixedSize(horizontal: false, vertical: true)
                }
                #expect(size.width == Self.width, "\(name) is \(size.width) pt wide")
                #expect(size.height <= Self.maxHeight, "\(name) is \(size.height) pt tall")
            }
        }
    }

    @Test("the Lock Screen view still fits when Always-On dims it")
    func lockScreenDimmed() throws {
        let now = Date.now
        let size = try Self.shoot(name: "lock-delayed-always-on") { _ in
            LiveActivityLockScreenView(attributes: Self.longest(.delayed),
                                       state: LiveActivitySamples.state(.delayed, now: now), art: Self.heroArt,
                                       now: now, formatter: Self.formatter)
                .frame(width: Self.width)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.isLuminanceReduced, true)
        }
        #expect(size.height <= Self.maxHeight)
    }

    @Test("the minimal view fits 28 pt when the island is limited, counting down and out now, with and without art",
          arguments: [LiveActivitySamples.Case.countingDown, .outNow])
    func minimalLimited(sample: LiveActivitySamples.Case) throws {
        let now = Date.now
        let mark = Self.ringMark(show: Self.show(sample))
        for option in Self.artOptions {
            let name = "minimal-limited-\(sample.rawValue)\(option.suffix)"
            let size = try Self.shoot(name: name, holes: option.art ? [mark] : nil) { poster in
                LiveActivityMinimalView(attributes: Self.longest(sample),
                                        state: LiveActivitySamples.state(sample, now: now),
                                        poster: poster, now: now, formatter: Self.formatter)
                    .fixedSize()
            }
            #expect(size.width <= LiveActivityMinimalView.limitedWidth, "\(name) is \(size.width) pt wide")
            #expect(size.height <= LiveActivityMinimalView.limitedWidth, "\(name) is \(size.height) pt tall")
        }
    }

    @Test("the Dynamic Island and small-family views render in every state, with and without art",
          arguments: Shot.allCases)
    func islandRenders(shot: Shot) throws {
        let now = Date.now
        let attributes = LiveActivitySamples.attributes(shot.sample, now: now)
        let state = LiveActivitySamples.state(shot.sample, now: now)
        let stale = shot == .stale
        let show = Self.show(shot.sample)
        for option in Self.artOptions {
            let holes = { (hole: ArtHoleExpectation) in option.art ? [hole] : nil }
            let compactMark = Self.mark(24, show: show)
            try Self.shoot(name: "compact-\(shot.rawValue)\(option.suffix)", holes: holes(compactMark)) { poster in
                HStack {
                    LiveActivityCompactView(slot: .leading, attributes: attributes, state: state, poster: poster,
                                            isStale: stale, now: now, formatter: Self.formatter)
                    Spacer(minLength: 120)
                    LiveActivityCompactView(slot: .trailing, attributes: attributes, state: state, isStale: stale,
                                            now: now, formatter: Self.formatter)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .fixedSize()
            }

            let ring = Self.ringMark(show: show)
            try Self.shoot(name: "minimal-\(shot.rawValue)\(option.suffix)", holes: holes(ring)) { poster in
                LiveActivityMinimalView(attributes: attributes, state: state, poster: poster, isStale: stale, now: now,
                                        formatter: Self.formatter)
                    .padding(6)
                    .fixedSize()
            }

            // The regions as the island lays them out: leading and trailing side by side, the bottom across. The art
            // is the wide key art cropped square (`ActivityArt.hero`), rounded 12.
            let size = LiveActivityExpandedView.artSize
            let art = ArtHoleExpectation.patch(size: CGSize(width: size, height: size), radius: 12, circle: false,
                                               show: show, kind: "wide")
            let name = "expanded-\(shot.rawValue)\(option.suffix)"
            let expandedSize = try Self.shoot(name: name, holes: holes(art)) { image in
                VStack(spacing: 8) {
                    HStack(alignment: .top) {
                        LiveActivityExpandedView(region: .leading, attributes: attributes, state: state,
                                                 isStale: stale, now: now, formatter: Self.formatter)
                        LiveActivityExpandedView(region: .trailing, attributes: attributes, state: state, art: image,
                                                 poster: image, isStale: stale, now: now, formatter: Self.formatter)
                    }
                    LiveActivityExpandedView(region: .bottom, attributes: attributes, state: state, isStale: stale,
                                             now: now, formatter: Self.formatter)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                .frame(width: 371)
                .fixedSize(horizontal: false, vertical: true)
            }
            #expect(expandedSize.height <= 160, "\(name) is \(expandedSize.height) pt tall")

            try Self.shoot(name: "small-\(shot.rawValue)\(option.suffix)", background: LiveActivityInk.base,
                           holes: holes(Self.mark(18, show: show))) { poster in
                LiveActivitySmallView(attributes: attributes, state: state, poster: poster, isStale: stale, now: now,
                                      formatter: Self.formatter)
                    .padding(12)
                    .frame(width: 170)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @Test("the ring and bar fill from the activity's start to the drop, 2 hours without one, never backwards")
    func fillWindow() {
        let drop = Date(timeIntervalSince1970: 1_800_000_000)
        var attributes = LiveActivitySamples.attributes(.countingDown)
        attributes.windowStart = drop - 45 * 60
        #expect(attributes.window(until: drop) == (drop - 45 * 60)...drop)
        #expect(attributes.window(until: drop).fraction(at: drop - 15 * 60) == 2.0 / 3)
        attributes.windowStart = nil
        #expect(attributes.window(until: drop) == (drop - 2 * 3_600)...drop)
        // Moved earlier than the activity's start: a minute's window, full once the drop has passed.
        attributes.windowStart = drop + 600
        #expect(attributes.window(until: drop) == (drop - 60)...drop)
        #expect(attributes.window(until: drop).fraction(at: drop + 1) == 1)
    }

    @Test("no Live Activity view uses a counting-up text style (CLAUDE.md rule 4)")
    func noTimerStyle() throws {
        let files = try ["Shared/LiveActivity", "MeridianWidgets"].flatMap { path in
            try FileManager.default.contentsOfDirectory(at: Self.root.appendingPathComponent(path),
                                                        includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "swift" }
        }
        #expect(files.contains { $0.lastPathComponent == "DropLiveActivity.swift" })
        #expect(files.contains { $0.lastPathComponent == "LiveActivityCountdown.swift" })
        let banned = try Regex(#"style:\s*\.(timer|relative)\b|\.timer\b"#)
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            #expect(source.firstMatch(of: banned) == nil, "\(file.lastPathComponent) uses a counting-up text style")
        }
    }
}
