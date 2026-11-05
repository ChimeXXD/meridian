import SwiftUI

/// Welcome's wall of art: three staggered rows of posters and wide key art that drift slowly, alternating direction,
/// and fade out into the night above the headline. Still with Reduce Motion. Decorative, so VoiceOver skips it. Each
/// picture fades in as it loads (0.35 s ease-out, the app's art fade); one that fails leaves a faint tile.
struct WelcomeWallView: View {
    let wall: WelcomeWall
    var night: Color = ArtworkPalette.neutral.night.color

    /// Row heights: a tall middle row between two shorter ones, so the wall isn't a shelf.
    static let heights: [CGFloat] = [128, 172, 128]
    static let spacing: CGFloat = 8
    /// Staggered starts, as in Mindvalley: no two rows line up their edges.
    static let leads: [CGFloat] = [0, 0.42, 0.18]

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
            ForEach(Array(wall.rows.enumerated()), id: \.offset) { index, row in
                WallRow(tiles: row, height: Self.heights[index % Self.heights.count], leftward: index % 2 == 0,
                        lead: Self.leads[index % Self.leads.count])
            }
        }
        // Dimmed a little so the headline stays the hero, then faded out by the rows' own bottom edge: a fade over
        // the whole frame left the last row ending in a hard line behind "Meridian" (simulator, 2 Nov).
        .overlay(night.opacity(0.18))
        .mask {
            // Eased, and clear before the last row's edge, so its corners never show as a line.
            LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.35),
                                   .init(color: .black.opacity(0.35), location: 0.68),
                                   .init(color: .clear, location: 0.9)], startPoint: .top, endPoint: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
        .overlay(alignment: .top) {
            // Night under the status bar, so the time and battery stay readable over bright art.
            LinearGradient(colors: [night.opacity(0.7), night.opacity(0)], startPoint: .top, endPoint: .bottom)
                .frame(height: 96)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// One row: its tiles three times over, sliding by exactly one run and then repeating, so the loop never jumps. The
/// offset is worked out from the clock on each frame (30 a second) rather than with a repeating animation, which kept
/// pictures that loaded after it started from ever drawing (seen on the simulator, 2 Nov).
private struct WallRow: View {
    let tiles: [WelcomeWall.Tile]
    let height: CGFloat
    let leftward: Bool
    /// How far into its run the row starts, as a fraction of the run.
    let lead: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Wider than any iPhone, in landscape too. A fixed bound, because measuring the row fed its own width back into
    /// the strip's length and hung layout (simulator, 2 Nov).
    private static let widestScreen: CGFloat = 1_000

    private func width(_ tile: WelcomeWall.Tile) -> CGFloat {
        tile.shape == .poster ? (height * 2 / 3).rounded() : (height * 16 / 9).rounded()
    }

    private var run: CGFloat { tiles.reduce(0) { $0 + width($1) + WelcomeWallView.spacing } }

    /// Runs in the strip: enough that the screen is covered at every phase of the slide, at least three. A short row
    /// (three posters) is narrower than a landscape screen, so a fixed count left a gap at its end.
    private var copies: Int {
        guard run > 0 else { return 3 }
        return max(3, Int((Self.widestScreen / run).rounded(.up)) + 1)
    }

    /// The longest side to decode. A wide tile can hold an AniList banner, about five times wider than tall, which
    /// fills the tile's height and spills past its width; decoding it to the tile's width left it upscaled and soft.
    private func decodeLength(_ tile: WelcomeWall.Tile) -> CGFloat {
        tile.shape == .poster ? max(width(tile), height) : height * 5
    }

    var body: some View {
        strip
            .modifier(Drift(run: run, lead: lead, leftward: leftward, paused: reduceMotion))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
    }

    private var strip: some View {
        HStack(spacing: WelcomeWallView.spacing) {
            ForEach(0..<copies, id: \.self) { _ in
                ForEach(tiles) { tile in
                    WallTile(url: tile.url, width: width(tile), height: height, decodeLength: decodeLength(tile))
                }
            }
        }
        .fixedSize()
    }
}

/// Slides a row from the clock. A modifier, so each frame re-evaluates only the offset: `content` is the strip
/// already built, rather than every tile view rebuilt and diffed 30 times a second.
private struct Drift: ViewModifier {
    let run: CGFloat
    /// How far into its run the row starts, as a fraction of the run.
    let lead: CGFloat
    let leftward: Bool
    /// Reduce Motion: the row stays at its starting place.
    let paused: Bool

    @State private var origin = Date.now

    /// Points per second: slow enough to read as ambience, not a carousel.
    private static let speed: CGFloat = 9

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: paused)) { context in
            content.offset(x: offset(at: context.date))
        }
    }

    /// Leftward rows slide from 0 to -run, rightward ones from -run to 0, each starting `lead` of a run in. The strip
    /// is `copies` runs long, so at least `copies - 1` runs (as wide as the screen) always cover it.
    private func offset(at date: Date) -> CGFloat {
        guard run > 0 else { return 0 }
        let travelled = paused ? 0 : CGFloat(date.timeIntervalSince(origin)) * Self.speed
        let phase = (run * lead + travelled).truncatingRemainder(dividingBy: run)
        return leftward ? -phase : phase - run
    }
}

private struct WallTile: View {
    let url: URL
    let width: CGFloat
    let height: CGFloat
    /// The longest side to decode, in points.
    let decodeLength: CGFloat

    @Environment(\.displayScale) private var scale
    @State private var image: UIImage?

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.05))
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill().transition(.opacity)
                        .accessibilityIgnoresInvertColors()
                }
            }
            .frame(width: width, height: height)
            .clipShape(.rect(cornerRadius: 10))
            .task(id: url) {
                let maxPixel = Int(decodeLength * scale)
                guard let loaded = try? await ArtworkLoader.shared.load(url, maxPixel: maxPixel) else { return }
                // Faded under Reduce Motion too: a fade moves nothing (AD-3); only the drift stops.
                withAnimation(.easeOut(duration: 0.35)) { image = loaded.image }
            }
    }
}
