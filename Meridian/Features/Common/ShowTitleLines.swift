import SwiftUI

/// How many lines a page's show title may take (AD-9, BU-7). Two at the usual sizes, shrinking to 70% before it's cut;
/// at the accessibility sizes four at full size, since a title shrunk to 70% ended up smaller than the out line under
/// it, and long anime titles were cut at two.
enum ShowTitleLines {
    static func limit(for size: DynamicTypeSize) -> Int { size.isAccessibilitySize ? 4 : 2 }
    static func minimumScale(for size: DynamicTypeSize) -> CGFloat { size.isAccessibilitySize ? 1 : 0.7 }
}

extension View {
    /// A show page's or the hero's title lines, by `ShowTitleLines`.
    func showTitleLines() -> some View { modifier(ShowTitleLinesModifier()) }
}

private struct ShowTitleLinesModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .lineLimit(ShowTitleLines.limit(for: dynamicTypeSize))
            .minimumScaleFactor(ShowTitleLines.minimumScale(for: dynamicTypeSize))
    }
}
