import SwiftUI

/// Search's grid before its posters arrive (EA-6): the header and 2:3 poster outlines with a title bar, three across
/// as the real grid is, so the posters land in place instead of replacing a spinner.
struct SearchPlaceholderGrid: View {
    let header: String
    /// What VoiceOver says while it waits ("Finding this week's shows").
    let label: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let columns = dynamicTypeSize.isAccessibilitySize ? 1 : 3
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            Text(header)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NightInk.muted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.s, alignment: .top),
                                     count: columns),
                      spacing: Tokens.Space.m) {
                ForEach(0..<(columns * 2), id: \.self) { _ in
                    VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.white.opacity(0.04))
                            .strokeBorder(.white.opacity(0.12))
                            .aspectRatio(2 / 3, contentMode: .fit)
                        LoadingBar { Text(verbatim: "Severance").font(.subheadline.weight(.medium)) }
                    }
                }
            }
        }
        .padding(.top, Tokens.Space.s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
