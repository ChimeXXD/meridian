import SwiftUI
import WidgetKit

/// A later show under the medium widget's hero, on one line (#Apple TV's rows, made small): its small poster, the name
/// in serif, when it's out in words (D-40), and its countdown on the right. "▯ Silo  Expected Wed 23:00 … 2d 4h".
struct WidgetCompactRow: View {
    let drop: Drop
    let now: Date
    var poster: UIImage?
    /// The poster column shows when any row has one; a row without keeps a quiet tile so the rows stay aligned.
    var showsPoster = false
    var formatter = DropFormatter()

    /// The poster's height; it is 2:3.
    static let posterHeight: CGFloat = 21

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        HStack(spacing: Tokens.Space.xs) {
            if showsPoster { WidgetPosterThumb(image: poster, height: Self.posterHeight) }
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xs) {
                Text(drop.showName)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.primary, when: dimmed))
                    .lineLimit(1)
                // A long name shortens before how sure the time is does (D-40).
                Text(WidgetText.when(drop, now: now, formatter: formatter))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.muted, when: dimmed))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: Tokens.Space.xs)
                CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now, size: 15,
                              tint: WidgetInk.dimmed(WidgetInk.secondary, when: dimmed), formatter: formatter,
                              alignment: .trailing, scalesWithText: false)
                    .environment(\.numeralStudy, .night)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetAccessibility.label(for: drop, now: now, formatter: formatter))
    }
}
