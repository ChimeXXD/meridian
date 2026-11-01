import SwiftUI
import WidgetKit

/// One of systemLarge's rows under the hero (systemMedium's are `WidgetCompactRow`): the show's small poster, the
/// show name in serif over when it's out (in words, D-40), and its countdown on the right.
struct MediumWidgetRow: View {
    let drop: Drop
    let now: Date
    var art: UIImage?
    /// The thumbnail column shows when any row has art; a row without keeps a quiet tile so the rows stay aligned.
    var showsThumbnail = false
    var formatter = DropFormatter()

    /// The poster's height; it is 2:3, as tall as the row.
    static let thumbnail: CGFloat = 32

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        HStack(spacing: Tokens.Space.s) {
            if showsThumbnail { WidgetPosterThumb(image: art, height: Self.thumbnail) }
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
                          tint: WidgetInk.primary, formatter: formatter, alignment: .trailing)
                .environment(\.numeralStudy, .night)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(height: 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetAccessibility.label(for: drop, now: now, formatter: formatter))
    }

}
