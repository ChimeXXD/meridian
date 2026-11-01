import SwiftUI
import Testing
import UIKit
@testable import Airstamp

/// SPEC acceptance and D5-1: the Lock Screen view is at most 160 pt tall at a 360 pt width with the longest show name,
/// in every state, with and without art, and the minimal view fits 28 pt when the island is limited in width. Every presentation is
/// rendered into `fidelity/shots/live-activity/` (git-ignored) for Chime to look at, as `WidgetRenderTests` does for
/// the widgets. Timers read against the real clock, so the samples are built around `Date.now`.
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

    /// Neutral placeholders, never real artwork (CLAUDE.md rule 9), in the shapes the App Group holds: 16:9 key art
    /// and a 2:3 poster, as `WidgetRenderTests` draws them.
    static let heroArt = placeholder(CGSize(width: 192, height: 108))
    static let poster = placeholder(CGSize(width: 20, height: 30))

    static func placeholder(_ size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor(white: 0.55, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(white: 0.8, alpha: 1).setFill()
            context.fill(CGRect(x: size.width / 6, y: size.height / 6, width: size.width * 2 / 3,
                                height: size.height * 5 / 12))
        }
    }

    /// Each view is shot without art (the Debug show, or art not saved yet) and with the placeholders.
    static let artOptions: [(suffix: String, art: UIImage?, poster: UIImage?)] = [("", nil, nil),
                                                                                  ("-art", heroArt, poster)]

    /// Renders at 3x into the shots folder and returns the size in points. The island is pure black; the Lock Screen
    /// banner draws its own background. The ring and bar are drawn as shapes, since `ImageRenderer` can't draw the
    /// system's live progress views.
    @discardableResult
    static func shoot(_ view: some View, name: String, background: Color = .black) throws -> CGSize {
        let renderer = ImageRenderer(content: view
            .background(background)
            .environment(\.colorScheme, .dark)
            .environment(\.liveActivityStaticProgress, true))
        renderer.scale = 3
        let image = try #require(renderer.uiImage, "\(name) didn't render")
        let folder = root.appendingPathComponent("fidelity/shots/live-activity", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try #require(image.pngData()).write(to: folder.appendingPathComponent("\(name).png"))
        return image.size
    }

    @Test("the Lock Screen view is at most 160 pt tall with the longest name, in every state, with and without art",
          arguments: Shot.allCases)
    func lockScreenHeight(shot: Shot) throws {
        let now = Date.now
        let samples = [("", LiveActivitySamples.attributes(shot.sample, now: now)),
                       ("-longest", Self.longest(shot.sample))]
        for (suffix, attributes) in samples {
            for option in Self.artOptions {
                let name = "lock-\(shot.rawValue)\(suffix)\(option.suffix)"
                let view = LiveActivityLockScreenView(attributes: attributes,
                                                      state: LiveActivitySamples.state(shot.sample, now: now),
                                                      art: option.art, isStale: shot == .stale, now: now,
                                                      formatter: Self.formatter)
                    .frame(width: Self.width)
                    .fixedSize(horizontal: false, vertical: true)
                let size = try Self.shoot(view, name: name)
                #expect(size.width == Self.width, "\(name) is \(size.width) pt wide")
                #expect(size.height <= Self.maxHeight, "\(name) is \(size.height) pt tall")
            }
        }
    }

    @Test("the Lock Screen view still fits when Always-On dims it")
    func lockScreenDimmed() throws {
        let now = Date.now
        let view = LiveActivityLockScreenView(attributes: Self.longest(.delayed),
                                              state: LiveActivitySamples.state(.delayed, now: now), art: Self.heroArt,
                                              now: now, formatter: Self.formatter)
            .frame(width: Self.width)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.isLuminanceReduced, true)
        let size = try Self.shoot(view, name: "lock-delayed-always-on")
        #expect(size.height <= Self.maxHeight)
    }

    @Test("the minimal view fits 28 pt when the island is limited, counting down and out now, with and without art",
          arguments: [LiveActivitySamples.Case.countingDown, .outNow])
    func minimalLimited(sample: LiveActivitySamples.Case) throws {
        let now = Date.now
        for option in Self.artOptions {
            let name = "minimal-limited-\(sample.rawValue)\(option.suffix)"
            let view = LiveActivityMinimalView(attributes: Self.longest(sample),
                                               state: LiveActivitySamples.state(sample, now: now),
                                               poster: option.poster, now: now, formatter: Self.formatter)
                .fixedSize()
            let size = try Self.shoot(view, name: name)
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
        for option in Self.artOptions {
            let compact = HStack {
                LiveActivityCompactView(slot: .leading, attributes: attributes, state: state, poster: option.poster,
                                        isStale: stale, now: now, formatter: Self.formatter)
                Spacer(minLength: 120)
                LiveActivityCompactView(slot: .trailing, attributes: attributes, state: state, isStale: stale,
                                        now: now, formatter: Self.formatter)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            try Self.shoot(compact.fixedSize(), name: "compact-\(shot.rawValue)\(option.suffix)")

            let minimal = LiveActivityMinimalView(attributes: attributes, state: state, poster: option.poster,
                                                  isStale: stale, now: now, formatter: Self.formatter)
                .padding(6)
            try Self.shoot(minimal.fixedSize(), name: "minimal-\(shot.rawValue)\(option.suffix)")

            // The regions as the island lays them out: leading and trailing side by side, the bottom across.
            let expanded = VStack(spacing: 8) {
                HStack(alignment: .top) {
                    LiveActivityExpandedView(region: .leading, attributes: attributes, state: state, isStale: stale,
                                             now: now, formatter: Self.formatter)
                    LiveActivityExpandedView(region: .trailing, attributes: attributes, state: state, art: option.art,
                                             poster: option.poster, isStale: stale, now: now,
                                             formatter: Self.formatter)
                }
                LiveActivityExpandedView(region: .bottom, attributes: attributes, state: state, isStale: stale,
                                         now: now, formatter: Self.formatter)
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .frame(width: 371)
            .fixedSize(horizontal: false, vertical: true)
            let name = "expanded-\(shot.rawValue)\(option.suffix)"
            let size = try Self.shoot(expanded, name: name)
            #expect(size.height <= 160, "\(name) is \(size.height) pt tall")

            let small = LiveActivitySmallView(attributes: attributes, state: state, poster: option.poster,
                                              isStale: stale, now: now, formatter: Self.formatter)
                .padding(12)
                .frame(width: 170)
                .fixedSize(horizontal: false, vertical: true)
            try Self.shoot(small, name: "small-\(shot.rawValue)\(option.suffix)", background: LiveActivityInk.base)
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
        let files = try ["Shared/LiveActivity", "AirstampWidgets"].flatMap { path in
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
