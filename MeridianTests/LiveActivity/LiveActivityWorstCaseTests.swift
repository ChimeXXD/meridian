import SwiftUI
import Testing
import UIKit
@testable import Meridian

/// The Live Activity's worst cases from break-ui (5 Nov): a 60-character name with four more merged in, a long
/// provider, a running activity delayed by a day, one second to go, an emoji-only title, and the largest text size.
/// Rendered into `fidelity/shots/worst-cases/` (git-ignored) to look at, never copied to the design system.
extension LiveActivityLayoutTests {
    /// Renders at 3x over `background` into the worst-case folder.
    static func worstShot<V: View>(_ name: String, background: Color = .black, size: DynamicTypeSize = .large,
                                   _ view: V) throws -> UIImage {
        let renderer = ImageRenderer(content: view
            .background(background)
            .environment(\.colorScheme, .dark)
            .environment(\.dynamicTypeSize, size)
            .environment(\.liveActivityStaticProgress, true))
        renderer.scale = 3
        let image = try #require(renderer.uiImage, "\(name) didn't render")
        try FileManager.default.createDirectory(at: WidgetRenderTests.worstFolder, withIntermediateDirectories: true)
        try #require(image.pngData()).write(to: WidgetRenderTests.worstFolder.appendingPathComponent("\(name).png"))
        return image
    }

    static func lockScreen(_ attributes: DropActivityAttributes, _ state: DropActivityAttributes.ContentState)
        -> some View {
        LiveActivityLockScreenView(attributes: attributes, state: state, now: now, formatter: formatter)
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
    }

    @Test("the small family keeps '+ 4 more' after a long name")
    func smallKeepsMore() throws {
        let image = try Self.worstShot("small-longMerged", background: LiveActivityInk.base,
                                       LiveActivitySmallView(attributes: LiveActivitySamples.attributes(.longMerged,
                                                                                                        now: Self.now),
                                                             state: LiveActivitySamples.state(.longMerged, now: Self.now),
                                                             now: Self.now, formatter: Self.formatter)
                                           .padding(12)
                                           .frame(width: 170)
                                           .fixedSize(horizontal: false, vertical: true))
        let text = try WidgetRenderTests.words(in: image)
        #expect(text.contains("4 more"), "small reads: \(text)")
    }

    /// A running activity delayed by a day counts past 24 hours ("26:00:00"), wider than the slot.
    @Test("the compact island's timer fits its slot at its smallest scale, whatever the digits")
    func compactTimerWidth() throws {
        let smallest = 15 * LiveActivityCompactView.timerMinimumScale
        for value in ["88:88:88", "26:00:00"] {
            let renderer = ImageRenderer(content: Text(verbatim: value)
                .font(NumeralStudy.night.font(size: smallest, weight: .medium))
                .fixedSize())
            let image = try #require(renderer.uiImage)
            #expect(image.size.width <= LiveActivityCompactView.timerWidth, "\(value) is \(image.size.width) pt wide")
        }
    }

    @Test("the Lock Screen banner stays within 160 pt with a two-line title, in every worst case, at every text size")
    func lockScreenWorstCases() throws {
        for worst in LiveActivitySamples.WorstCase.allCases {
            for size in [DynamicTypeSize.large, .accessibility5] {
                let name = "lock-\(worst.rawValue)\(size == .large ? "" : "-ax5")"
                let image = try Self.worstShot(name, size: size,
                                               Self.lockScreen(LiveActivitySamples.attributes(worst, now: Self.now),
                                                               LiveActivitySamples.state(worst, now: Self.now)))
                #expect(image.size.height <= Self.maxHeight, "\(name) is \(image.size.height) pt tall")
            }
        }
        // The long name takes its second line rather than stopping at about 20 characters (break-ui BU-9).
        let short = try Self.worstShot("lock-short", Self.lockScreen(LiveActivitySamples.attributes(.countingDown,
                                                                                                    now: Self.now),
                                                                     LiveActivitySamples.state(.countingDown,
                                                                                               now: Self.now)))
        let long = try Self.worstShot("lock-longMerged", Self.lockScreen(LiveActivitySamples.attributes(.longMerged,
                                                                                                       now: Self.now),
                                                                         LiveActivitySamples.state(.longMerged,
                                                                                                   now: Self.now)))
        #expect(long.size.height >= short.size.height + 18, "the long title is on one line")
    }

    @Test("the island and small family render the worst cases, to look at")
    func islandWorstCases() throws {
        for worst in LiveActivitySamples.WorstCase.allCases {
            let attributes = LiveActivitySamples.attributes(worst, now: Self.now)
            let state = LiveActivitySamples.state(worst, now: Self.now)
            _ = try Self.worstShot("compact-\(worst.rawValue)", HStack {
                LiveActivityCompactView(slot: .leading, attributes: attributes, state: state, now: Self.now,
                                        formatter: Self.formatter)
                Spacer(minLength: 120)
                LiveActivityCompactView(slot: .trailing, attributes: attributes, state: state, now: Self.now,
                                        formatter: Self.formatter)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .fixedSize())
            _ = try Self.worstShot("minimal-\(worst.rawValue)",
                                   LiveActivityMinimalView(attributes: attributes, state: state, now: Self.now,
                                                           formatter: Self.formatter)
                                       .padding(6).fixedSize())
            _ = try Self.worstShot("expanded-\(worst.rawValue)", VStack(spacing: 8) {
                HStack(alignment: .top) {
                    LiveActivityExpandedView(region: .leading, attributes: attributes, state: state, now: Self.now,
                                             formatter: Self.formatter)
                    LiveActivityExpandedView(region: .trailing, attributes: attributes, state: state, now: Self.now,
                                             formatter: Self.formatter)
                }
                LiveActivityExpandedView(region: .bottom, attributes: attributes, state: state, now: Self.now,
                                         formatter: Self.formatter)
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .frame(width: 371)
            .fixedSize(horizontal: false, vertical: true))
            _ = try Self.worstShot("small-\(worst.rawValue)", background: LiveActivityInk.base,
                                   LiveActivitySmallView(attributes: attributes, state: state, now: Self.now,
                                                         formatter: Self.formatter)
                                       .padding(12).frame(width: 170).fixedSize(horizontal: false, vertical: true))
        }
    }
}
