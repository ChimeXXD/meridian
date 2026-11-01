import SwiftUI

/// The filters over Search's airing grid, one picked at a time like the TV | Anime switch above it (Chime, D-43):
/// Popular, Today, New seasons, Exact time, then the services in the grid. Night Sky chips: the picked one is white
/// with black text, the rest are dark with a hairline, like the follow button.
struct SearchFilterRow: View {
    let options: [SearchFilter]
    @Binding var selection: SearchFilter
    /// Netflix's own Top 10 for the viewer's country, last in the row; it opens Netflix instead of filtering (O-13).
    var netflix: NetflixTopTenLink? = nil

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Tokens.Space.xs) {
                ForEach(options, id: \.self) { option in
                    chip(option)
                }
                if let netflix { link(netflix) }
            }
            .padding(.vertical, Tokens.Space.xxs)
        }
        // Runs to the screen's edges while the first chip lines up with the page margin.
        .contentMargins(.horizontal, Tokens.Space.m, for: .scrollContent)
        .padding(.horizontal, -Tokens.Space.m)
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("search-filters")
    }

    private func chip(_ option: SearchFilter) -> some View {
        let picked = option == selection
        return Button {
            selection = option
        } label: {
            Text(option.label)
                .font(.subheadline.weight(.medium))
                .modifier(ChipCapsule(picked: picked))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(picked ? .isSelected : [])
        .accessibilityIdentifier(option.identifier)
    }

    /// Looks like an unpicked chip with an arrow, because it leaves the app.
    private func link(_ netflix: NetflixTopTenLink) -> some View {
        Link(destination: netflix.url) {
            Label(netflix.label, systemImage: "arrow.up.right")
                .labelStyle(TrailingIcon())
                .font(.subheadline.weight(.medium))
                .modifier(ChipCapsule(picked: false))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(netflix.label)
        .accessibilityHint("Opens Netflix")
        .accessibilityIdentifier("search-netflix-top10")
    }

    /// The Night Sky chip: white with black text when picked, else dark with a hairline.
    private struct ChipCapsule: ViewModifier {
        let picked: Bool

        func body(content: Content) -> some View {
            content
                .foregroundStyle(picked ? .black : .white)
                .padding(.horizontal, Tokens.Space.s)
                .frame(minHeight: 34)
                .background(picked ? AnyShapeStyle(.white) : AnyShapeStyle(.black.opacity(0.55)), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(picked ? 0 : 0.35)))
                // Inside the label, so the whole 44 pt row is the tap area, not just the 34 pt capsule.
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
    }

    private struct TrailingIcon: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: Tokens.Space.xxs) {
                configuration.title
                configuration.icon.imageScale(.small)
            }
        }
    }
}
