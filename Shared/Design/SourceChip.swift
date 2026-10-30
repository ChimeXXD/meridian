import SwiftUI
import WidgetKit

/// Glyph + word saying where a time came from (CLAUDE.md rule 3; #31 WHOOP, #33 Any Distance).
/// In tinted or accented widgets the ink becomes primary; the glyph and word still say which source it is.
struct SourceChip: View {
    let content: SourceChipContent
    /// Night Sky's signature (D-39): a small dot in the status ink and the word in secondary text, no capsule and
    /// no symbol, so the dot is the only colour outside the artwork. The word keeps it from relying on colour.
    var plain = false

    @Environment(\.widgetRenderingMode) private var renderingMode

    init(source: ReleaseSource, confidence: Confidence, plain: Bool = false) {
        content = SourceChipContent(source: source, confidence: confidence)
        self.plain = plain
    }

    var body: some View {
        let ink = renderingMode == .fullColor ? Color(uiColor: content.kind.ink) : .primary
        Group {
            if plain {
                HStack(spacing: 6) {
                    Circle().fill(ink).frame(width: 6, height: 6)
                    Text(content.label)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
            } else {
                Label(content.label, systemImage: content.kind.glyph)
                    .labelStyle(.titleAndIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .padding(.horizontal, Tokens.Space.xs)
                    .padding(.vertical, Tokens.Space.xxs)
                    .background(ink.opacity(Tokens.chipFillOpacity), in: Capsule())
            }
        }
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
