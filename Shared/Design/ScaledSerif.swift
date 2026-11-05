import SwiftUI

/// A New York title at its designed size that grows with the text size like `style` (UX audit #3): fixed
/// `.system(size:design:)` titles never grew, so at the largest sizes a show's name ended up smaller than the lines
/// under it. Widgets and Live Activities keep fixed sizes, since they draw on a fixed canvas.
struct ScaledSerif: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    @ScaledMetric private var scale: CGFloat

    init(size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle) {
        self.size = size
        self.weight = weight
        _scale = ScaledMetric(wrappedValue: 1, relativeTo: style)
    }

    /// Headings of 28 pt and up set tight: at body leading their wrapped lines ran about 1.2 apart and read as two
    /// separate lines (AD-10). Smaller titles keep the standard leading.
    func body(content: Content) -> some View {
        content.font(.system(size: size * scale, weight: weight, design: .serif).leading(size >= 28 ? .tight : .standard))
    }
}

extension View {
    /// `.serif(20, relativeTo: .title3)`: 20 pt New York at the default size, growing as `.title3` does.
    func serif(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle) -> some View {
        modifier(ScaledSerif(size: size, weight: weight, relativeTo: style))
    }
}
