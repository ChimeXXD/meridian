import SwiftUI

/// The Longitudes mark (D-54): a globe drawn only by its meridians, yours at full strength rising past the globe to a
/// star in Meridian Gold (D-53). Drawn from the app icon's 100-unit grid (`scripts/make-app-icon.swift`, the design
/// system's `logoInner`), so it stays sharp at any size. Decorative: the wordmark beside it carries the name.
/// Sized by its height: the lines span only the middle 64% of the grid's width, so a lockup can give it a frame that
/// narrow (`width = height * widthRatio`) without the mark shrinking or leaving a gap beside the name.
struct MeridianMark: View {
    /// The narrowest frame width, as a share of its height, that still holds every line.
    static let widthRatio: CGFloat = 0.64

    var ink = Color(uiColor: Tokens.starlight)
    var star = Color(uiColor: Tokens.gold)

    private static let meridians: [CGFloat] = [22.28, 28.79, 38.52, 61.48, 71.21, 77.72]

    var body: some View {
        Canvas { context, size in
            let unit = size.height / 100
            context.translateBy(x: (size.width - unit * 100) / 2, y: (size.height - unit * 100) / 2)
            context.scaleBy(x: unit, y: unit)
            let round = StrokeStyle(lineWidth: 2.5, lineCap: .round)

            // The other meridians: 32% strength, clipped to the globe.
            var globe = context
            globe.clip(to: Path(ellipseIn: CGRect(x: 20, y: 26, width: 60, height: 60)))
            var lines = Path()
            for x in Self.meridians {
                lines.move(to: CGPoint(x: x, y: 20))
                lines.addLine(to: CGPoint(x: x, y: 92))
            }
            globe.stroke(lines, with: .color(ink.opacity(0.32)), style: round)

            // Yours, and its star.
            var yours = Path()
            yours.move(to: CGPoint(x: 50, y: 86))
            yours.addLine(to: CGPoint(x: 50, y: 20))
            context.stroke(yours, with: .color(ink), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: 46.5, y: 8.5, width: 7, height: 7)), with: .color(star))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 24) {
        MeridianMark().frame(width: 23, height: 36)
        MeridianMark().frame(width: 64, height: 64)
        MeridianMark().frame(width: 128, height: 128)
    }
    .padding(32)
    .background(Color(red: 0.11, green: 0.11, blue: 0.11))
}
