import SwiftUI

/// The filters over Search's airing grid, one picked at a time like the TV | Anime switch above it (Chime, D-43):
/// Popular, Today, New seasons, Exact time, then the 12 major platforms in a fixed order (D-45), each with its logo
/// (D-44). Night Sky
/// chips: the picked one is white with black text, the rest are dark with a hairline, like the follow button.
struct SearchFilterRow: View {
    let options: [SearchFilter]
    @Binding var selection: SearchFilter
    var logos: NetworkLogos = .empty
    /// Counts chip taps, so the selection tick follows a tap only, not TV | Anime swapping in the other kind's filter.
    @State private var taps = 0

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: Tokens.Space.xs) {
                    ForEach(options, id: \.self) { option in
                        chip(option).id(option)
                    }
                }
                .padding(.vertical, Tokens.Space.xxs)
            }
            // Runs to the screen's edges while the first chip lines up with the page margin.
            .contentMargins(.horizontal, Tokens.Space.m, for: .scrollContent)
            .padding(.horizontal, -Tokens.Space.m)
            .scrollIndicators(.hidden)
            // A picked service further along stays in view when Search comes back or TV | Anime switches.
            // After this layout pass, or the row hasn't measured its chips yet and stops short.
            .onAppear { Task { @MainActor in proxy.scrollTo(selection, anchor: .center) } }
            .onChange(of: options) { Task { @MainActor in proxy.scrollTo(selection, anchor: .center) } }
        }
        .sensoryFeedback(.selection, trigger: taps)
        .accessibilityIdentifier("search-filters")
    }

    private func chip(_ option: SearchFilter) -> some View {
        let picked = option == selection
        return Button {
            if !picked { taps += 1 }
            selection = option
        } label: {
            HStack(spacing: 0) {
                if case .service(let label) = option,
                   let logo = PopularServices.service(label)?.names.lazy.compactMap(logos.image(for:)).first {
                    LogoTile(url: logo)
                }
                Text(option.label)
            }
            .font(.subheadline.weight(.medium))
            .modifier(ChipCapsule(picked: picked))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(picked ? .isSelected : [])
        .accessibilityIdentifier(option.identifier)
    }

    /// A service's logo on a small white rounded tile, so dark wordmarks read on the Night Sky chip. The white tile
    /// appears only once its logo has loaded, so a logo that can't load (offline, a renamed file) never leaves an empty
    /// box. The chip's name says the same, so VoiceOver skips it.
    private struct LogoTile: View {
        let url: URL

        var body: some View {
            ArtworkLoaderView(url: url, maxPixel: 120) { loaded in
                if let image = loaded?.image {
                    Image(uiImage: image).resizable().scaledToFit().padding(3)
                        .frame(width: 30, height: 22)
                        .background(.white, in: RoundedRectangle(cornerRadius: 5))
                        .accessibilityIgnoresInvertColors()  // the white tile too, or Smart Invert blacks it out
                        .padding(.trailing, Tokens.Space.xs)
                } else {
                    // The tile's space, clear: the row keeps its width (and its scroll) while logos load, and one
                    // that can't load leaves a gap, never a white box.
                    Color.clear.frame(width: 30, height: 22).padding(.trailing, Tokens.Space.xs)
                }
            }
            .accessibilityHidden(true)
        }
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
}
