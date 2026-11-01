import SwiftUI
import WidgetKit

/// What the Home Screen widgets say with nothing to count down, bottom-left like their countdowns: "Follow a show" /
/// "Its countdown shows up here.", or "Silo returns Fri 9 Jul 2027" / "Nothing else is scheduled."
struct WidgetEmptyState: View {
    let moment: WidgetMoment
    var lineLimit = 2
    var formatter = DropFormatter()

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Spacer(minLength: 0)
            Text(WidgetText.emptyHeadline(moment, formatter: formatter))
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundStyle(WidgetInk.primary)
                .lineLimit(lineLimit).minimumScaleFactor(0.8)
                .widgetAccentable()
            Text(WidgetText.emptyDetail(moment))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WidgetInk.dimmed(WidgetInk.secondary, when: dimmed))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
