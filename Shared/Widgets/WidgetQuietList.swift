import SwiftUI
import WidgetKit

/// The medium and large widgets when shows are followed but none has a next episode (D-48): "Nothing scheduled" in
/// serif, then the shows themselves as quiet rows with their posters, so the widget still shows what's followed.
struct WidgetQuietList: View {
    let moment: WidgetMoment
    var posters: [String: UIImage] = [:]
    /// How many rows fit.
    let shown: Int
    var posterHeight: CGFloat = WidgetCompactRow.posterHeight
    var detailed = false
    var formatter = DropFormatter()

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        VStack(alignment: .leading, spacing: detailed ? Tokens.Space.xs : 3) {
            Spacer(minLength: 0)
            Text(WidgetText.emptyHeadline(moment, formatter: formatter))
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundStyle(WidgetInk.primary)
                .widgetAccentable()
                .padding(.bottom, Tokens.Space.xxs)
            ForEach(shows, id: \.showID) { show in
                WidgetQuietRow(show: show, now: moment.date, poster: posters[show.showID],
                               showsPoster: !dimmed && shows.contains { posters[$0.showID] != nil },
                               posterHeight: posterHeight, detailed: detailed,
                               // Under "Silo returns …" the rows still need to say they have nothing scheduled.
                               showsLabel: moment.nextReturn != nil, formatter: formatter)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .accessibilityElement(children: .contain)
    }

    private var shows: [QuietShow] { moment.quietRows(showing: shown) }
}
