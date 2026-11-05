import SwiftUI
import Testing
@testable import Meridian

/// Layout rules for the night pages that a screenshot alone wouldn't pin down.
@Suite("Night layout")
struct NightLayoutTests {
    /// A show with no art at all got 472 pt of empty night (EA-13); while its art is loading the space is kept, so
    /// nothing jumps when it arrives.
    @Test("a header without art is 200 pt; one waiting for art keeps its height", arguments: [
        (CGFloat(472), DynamicTypeSize.large, true, CGFloat(472)),
        (500, .large, true, 500),
        (472, .accessibility5, true, 280),
        (472, .large, false, 200),
        (500, .accessibility5, false, 200),
    ])
    @MainActor
    func headerHeight(height: CGFloat, size: DynamicTypeSize, hasArt: Bool, expected: CGFloat) {
        #expect(NightArtHeader.shownHeight(height, dynamicTypeSize: size, hasArt: hasArt) == expected)
    }

    /// At the accessibility sizes a long title was cut at 2 lines and shrunk to 70%, smaller than the line under it
    /// (AD-9, BU-7): it gets 4 lines at full size instead.
    @Test("show titles take up to 4 lines at full size at the accessibility sizes", arguments: [
        (DynamicTypeSize.large, 2, CGFloat(0.7)),
        (.xxxLarge, 2, 0.7),
        (.accessibility1, 4, 1),
        (.accessibility5, 4, 1),
    ])
    func titleLines(size: DynamicTypeSize, lines: Int, minimumScale: CGFloat) {
        #expect(ShowTitleLines.limit(for: size) == lines)
        #expect(ShowTitleLines.minimumScale(for: size) == minimumScale)
    }
}
