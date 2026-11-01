import SwiftUI
import WidgetKit

/// One of systemLarge's rows under the hero (systemMedium's are `WidgetCompactRow`): an optional small thumbnail, the
/// show name in serif over when it's out (in words, D-40), and its countdown on the right.
struct MediumWidgetRow: View {
    let drop: Drop
    let now: Date
    var art: UIImage?
    /// The thumbnail column shows when any row has art; a row without keeps a quiet tile so the rows stay aligned.
    var showsThumbnail = false
    var formatter = DropFormatter()

    static let thumbnail: CGFloat = 30

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        HStack(spacing: Tokens.Space.s) {
            if showsThumbnail { thumbnail(art) }
            VStack(alignment: .leading, spacing: 1) {
                Text(drop.showName)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.primary, when: dimmed))
                    .lineLimit(1)
                Text(WidgetText.outLine(drop, now: now, formatter: formatter))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.secondary, when: dimmed))
                    .lineLimit(1).minimumScaleFactor(0.85)
            }
            .layoutPriority(1)
            Spacer(minLength: Tokens.Space.xs)
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now, size: 22,
                          tint: WidgetInk.primary, formatter: formatter)
                .environment(\.numeralStudy, .night)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(height: 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetAccessibility.label(for: drop, now: now, formatter: formatter))
    }

    private func thumbnail(_ image: UIImage?) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(WidgetInk.tile)
            .overlay {
                if let image, !dimmed {
                    Image(uiImage: image)
                        .resizable()
                        .widgetAccentedRenderingMode(.desaturated)
                        .scaledToFill()
                }
            }
            .frame(width: Self.thumbnail, height: Self.thumbnail)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityHidden(true)
    }
}
