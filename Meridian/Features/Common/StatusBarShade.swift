import SwiftUI

/// Keeps the status bar readable when a page scrolls under it (EA-1, AD-4): the page colour, solid through the status
/// bar, then a 40 pt fade to clear. It was 0.9 fading over 110 pt, which left the clock on half-covered digits.
struct StatusBarShade: View {
    let color: Color
    var fade: CGFloat = 40

    var body: some View {
        // Placed in the safe area, the reader still reports the inset above it: the status bar, plus a show page's
        // invisible bar, whose back button the shade keeps clear too. The shade draws up over it, solid, then fades.
        // (Ignoring the safe area instead reports an inset of 0, and a 0 pt frame can't grow into it: tried, 5 Nov.)
        GeometryReader { proxy in
            let statusBar = proxy.safeAreaInsets.top
            LinearGradient(stops: [.init(color: color, location: 0),
                                   .init(color: color, location: statusBar / (statusBar + fade)),
                                   .init(color: color.opacity(0), location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: statusBar + fade)
                .offset(y: -statusBar)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// A night page that runs under the status bar: the scroll view ignores the top safe area, and the shade appears
    /// once its content reaches the status bar. Over the art it would be a band across the picture, so it fades in
    /// over the 60 pt before the text under the art gets there. `art` is the page's `NightArtHeader` height (0 when
    /// the page has none), shortened at the accessibility sizes as the header is.
    func statusBarShade(_ color: Color, art: CGFloat) -> some View {
        modifier(StatusBarShadeModifier(color: color, art: art))
    }
}

private struct StatusBarShadeModifier: ViewModifier {
    let color: Color
    let art: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// In 0.05 steps, so a scroll redraws only the shade, and only through its fade.
    @State private var shown: Double = 0

    /// Where the fade starts: the text under the art begins 64 pt above its bottom, and the status bar is about 60 pt.
    private var start: CGFloat {
        guard art > 0 else { return 0 }
        return max(0, NightArtHeader.shownHeight(art, dynamicTypeSize: dynamicTypeSize) - 64 - 60 - 60)
    }

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Double.self) { geometry in
                let offset = geometry.contentOffset.y + geometry.contentInsets.top
                let fraction = Double(min(1, max(0, (offset - start) / 60)))
                return (fraction * 20).rounded() / 20
            } action: { _, value in
                shown = value
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) { StatusBarShade(color: color).opacity(shown) }
    }
}
