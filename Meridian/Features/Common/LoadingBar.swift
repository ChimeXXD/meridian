import SwiftUI

/// A line that hasn't loaded yet, drawn in the final layout instead of a spinner (EA-6, AD-6): `content` is a sample of
/// the real line in its real font, hidden, so the bar has its width and height and nothing moves when the words come.
struct LoadingBar<Content: View>: View {
    @ViewBuilder let content: Content

    /// The night pages' quiet surface, as an empty poster's.
    static var fill: Color { .white.opacity(0.08) }

    var body: some View {
        content
            .lineLimit(1)
            .hidden()
            // A bar the line's full height reads as a block; about the height of its capitals reads as text.
            .overlay { RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Self.fill).scaleEffect(y: 0.7) }
            .accessibilityHidden(true)
    }
}

/// A headline's countdown and out line while they load: the show page holds their space (EA-9), and Upcoming's
/// cold launch draws its hero this way (EA-6).
struct HeadlinePlaceholder: View {
    var countdownSize: CGFloat = 64

    /// The countdown's own growth (`CountdownSlot`), so the held space matches the digits at every text size.
    @ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            LoadingBar { Text(verbatim: "0:00:00").font(NumeralStudy.night.font(size: countdownSize * scale)) }
            LoadingBar { Text(verbatim: "Out tomorrow at 00:00").font(.body.weight(.medium)) }
                .padding(.top, Tokens.Space.xxs)
        }
    }
}

/// Upcoming's first launch, before any times arrive: the hero's layout in neutral bars on the night base, so the
/// countdown lands where the bars were.
struct UpcomingHeroPlaceholder: View {
    let base: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NightArtHeader(image: nil, base: base)
            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    LoadingBar { Text(verbatim: "Severance").serif(32, relativeTo: .largeTitle) }
                    HeadlinePlaceholder()
                }
                LoadingBar { Text(verbatim: "S1E1 · Apple TV").font(.footnote) }
            }
            .padding(.horizontal, Tokens.Space.l)
            .padding(.top, -64)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading your shows")
        .accessibilityIdentifier("upcoming-loading")
    }
}
