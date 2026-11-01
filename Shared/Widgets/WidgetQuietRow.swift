import SwiftUI
import WidgetKit

/// A followed show with no next episode in a widget's spare row (D-48): its small poster, its name, and "Nothing
/// scheduled" where a countdown would be. The large widget's taller row adds why, in the app's words ("Between
/// seasons", "Ended").
struct WidgetQuietRow: View {
    let show: QuietShow
    let now: Date
    var poster: UIImage?
    var showsPoster = false
    /// The poster's height: the medium's one-line row or the large's two-line one.
    var posterHeight: CGFloat = WidgetCompactRow.posterHeight
    /// Adds the reason under the name (the large widget).
    var detailed = false
    /// "Nothing scheduled" on the right; off under a "Nothing scheduled" headline, which already says it.
    var showsLabel = true
    var formatter = DropFormatter()

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        HStack(spacing: detailed ? Tokens.Space.s : Tokens.Space.xs) {
            if showsPoster { WidgetPosterThumb(image: poster, height: posterHeight) }
            VStack(alignment: .leading, spacing: 1) {
                Text(show.name)
                    .font(.system(size: detailed ? 15 : 14, design: .serif))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.secondary, when: dimmed))
                    .lineLimit(1)
                if detailed {
                    Text(reason)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WidgetInk.dimmed(WidgetInk.muted, when: dimmed))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: Tokens.Space.xs)
            if showsLabel {
                Text(WidgetText.nothingScheduled)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetInk.dimmed(WidgetInk.muted, when: dimmed))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(height: detailed ? MediumWidgetRow.thumbnail : nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(show.name), nothing scheduled, \(reason)")
    }

    /// "Between seasons", "Ended", without the last episode's date, which the row has no room for.
    private var reason: String {
        ReleaseWording.quietNote(status: show.status, lastAired: nil, formatter: formatter, now: now)
    }
}
