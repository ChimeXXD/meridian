import SwiftUI
import Testing
import UIKit
@testable import Airstamp

/// SPEC acceptance and D5-1: the Lock Screen view is at most 160 pt tall at a 360 pt width with the longest show name,
/// in every state, and the minimal view fits 28 pt when the island is limited in width. Every presentation is
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

    /// Renders at 3x into the shots folder and returns the size in points.
    @discardableResult
    static func shoot(_ view: some View, name: String) throws -> CGSize {
        let renderer = ImageRenderer(content: view
            .background(LiveActivityInk.base)
            .environment(\.colorScheme, .dark))
        renderer.scale = 3
        let image = try #require(renderer.uiImage, "\(name) didn't render")
        let folder = root.appendingPathComponent("fidelity/shots/live-activity", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try #require(image.pngData()).write(to: folder.appendingPathComponent("\(name).png"))
        return image.size
    }

    @Test("the Lock Screen view is at most 160 pt tall with the longest name, in every state", arguments: Shot.allCases)
    func lockScreenHeight(shot: Shot) throws {
        let now = Date.now
        for (suffix, attributes) in [("", LiveActivitySamples.attributes(shot.sample)), ("-longest", Self.longest(shot.sample))] {
            let view = LiveActivityLockScreenView(attributes: attributes,
                                                  state: LiveActivitySamples.state(shot.sample, now: now),
                                                  isStale: shot == .stale, now: now, formatter: Self.formatter)
                .frame(width: Self.width)
                .fixedSize(horizontal: false, vertical: true)
            let size = try Self.shoot(view, name: "lock-\(shot.rawValue)\(suffix)")
            #expect(size.width == Self.width, "lock-\(shot.rawValue)\(suffix) is \(size.width) pt wide")
            #expect(size.height <= Self.maxHeight, "lock-\(shot.rawValue)\(suffix) is \(size.height) pt tall")
        }
    }

    @Test("the Lock Screen view still fits when Always-On dims it")
    func lockScreenDimmed() throws {
        let now = Date.now
        let view = LiveActivityLockScreenView(attributes: Self.longest(.delayed),
                                              state: LiveActivitySamples.state(.delayed, now: now), now: now,
                                              formatter: Self.formatter)
            .frame(width: Self.width)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.isLuminanceReduced, true)
        let size = try Self.shoot(view, name: "lock-delayed-always-on")
        #expect(size.height <= Self.maxHeight)
    }

    @Test("the minimal view fits 28 pt wide when the island is limited, counting down and out now",
          arguments: [LiveActivitySamples.Case.countingDown, .outNow])
    func minimalLimited(sample: LiveActivitySamples.Case) throws {
        let now = Date.now
        let view = LiveActivityMinimalView(attributes: Self.longest(sample),
                                           state: LiveActivitySamples.state(sample, now: now), limited: true, now: now,
                                           formatter: Self.formatter)
            .fixedSize()
        let size = try Self.shoot(view, name: "minimal-limited-\(sample.rawValue)")
        #expect(size.width <= LiveActivityMinimalView.limitedWidth, "minimal is \(size.width) pt wide")
        #expect(size.height <= LiveActivityMinimalView.limitedWidth, "minimal is \(size.height) pt tall")
    }

    @Test("the Dynamic Island and small-family views render in every state", arguments: Shot.allCases)
    func islandRenders(shot: Shot) throws {
        let now = Date.now
        let attributes = LiveActivitySamples.attributes(shot.sample)
        let state = LiveActivitySamples.state(shot.sample, now: now)
        let stale = shot == .stale
        let compact = HStack {
            LiveActivityCompactView(slot: .leading, attributes: attributes, state: state, isStale: stale, now: now,
                                    formatter: Self.formatter)
            Spacer(minLength: 120)
            LiveActivityCompactView(slot: .trailing, attributes: attributes, state: state, isStale: stale, now: now,
                                    formatter: Self.formatter)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        try Self.shoot(compact.fixedSize(), name: "compact-\(shot.rawValue)")

        let minimal = LiveActivityMinimalView(attributes: attributes, state: state, isStale: stale, now: now,
                                              formatter: Self.formatter)
            .padding(6)
        try Self.shoot(minimal.fixedSize(), name: "minimal-\(shot.rawValue)")

        let expanded = VStack(spacing: 8) {
            HStack(alignment: .top) {
                LiveActivityExpandedView(region: .leading, attributes: attributes, state: state, isStale: stale,
                                         now: now, formatter: Self.formatter)
                LiveActivityExpandedView(region: .trailing, attributes: attributes, state: state, isStale: stale,
                                         now: now, formatter: Self.formatter)
            }
            LiveActivityExpandedView(region: .bottom, attributes: attributes, state: state, isStale: stale, now: now,
                                     formatter: Self.formatter)
        }
        .padding(16)
        .frame(width: 371)
        .fixedSize(horizontal: false, vertical: true)
        let size = try Self.shoot(expanded, name: "expanded-\(shot.rawValue)")
        #expect(size.height <= 160, "expanded-\(shot.rawValue) is \(size.height) pt tall")

        let small = LiveActivitySmallView(attributes: attributes, state: state, isStale: stale, now: now,
                                          formatter: Self.formatter)
            .padding(12)
            .frame(width: 170)
            .fixedSize(horizontal: false, vertical: true)
        try Self.shoot(small, name: "small-\(shot.rawValue)")
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
