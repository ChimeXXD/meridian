import SwiftUI
import WidgetKit

/// Glyph + word saying where a time came from (CLAUDE.md rule 3; #31 WHOOP, #33 Any Distance).
/// In tinted or accented widgets the ink becomes primary; the glyph and word still say which source it is.
struct SourceChip: View {
    let content: SourceChipContent

    @Environment(\.widgetRenderingMode) private var renderingMode

    init(source: ReleaseSource, confidence: Confidence) {
        content = SourceChipContent(source: source, confidence: confidence)
    }

    var body: some View {
        let ink = renderingMode == .fullColor ? Color(uiColor: content.kind.ink) : .primary
        Label(content.label, systemImage: content.kind.glyph)
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ink)
            .lineLimit(1)
            .padding(.horizontal, Tokens.Space.xs)
            .padding(.vertical, Tokens.Space.xxs)
            .background(ink.opacity(Tokens.chipFillOpacity), in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Source: \(content.label)")
            .accessibilityIdentifier("source-chip")
    }
}

#Preview("Every source") {
    VStack(alignment: .leading, spacing: Tokens.Space.xs) {
        SourceChip(source: .broadcast(network: "HBO"), confidence: .exact)
        SourceChip(source: .platformRule("Netflix rule"), confidence: .estimated)
        SourceChip(source: .override(note: "Marvel 18:00 PT"), confidence: .exact)
        SourceChip(source: .override(note: "Reported"), confidence: .estimated)
        SourceChip(source: .anilist, confidence: .exact)
        SourceChip(source: .dateOnly, confidence: .dateOnly)
    }
    .padding()
}
