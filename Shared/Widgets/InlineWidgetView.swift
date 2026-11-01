import SwiftUI
import WidgetKit

/// accessoryInline, the line above the Lock Screen clock: "Silo · 2d 4h" (SPEC §5). The system draws it in its own
/// font. Within a day the count is a ticking `Text(timerInterval:pauseTime:countsDown:)`, which stops at zero
/// (CLAUDE.md rule 4); the entry at the drop then says "Silo · Out now".
struct InlineWidgetView: View {
    let moment: WidgetMoment
    var formatter = DropFormatter()

    var body: some View {
        line
            .lineLimit(1)
            .widgetAccentable()
            .containerBackground(for: .widget) { Color.clear }
            .accessibilityIdentifier("widget-inline")
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(WidgetAccessibility.label(for: moment.spokenDrop, now: moment.date, formatter: formatter))
    }

    private var line: Text {
        // Only a ticking count has no static text, and it always has a current drop.
        guard let drop = moment.current, WidgetText.inline(moment, formatter: formatter) == nil else {
            return Text(WidgetText.inline(moment, formatter: formatter) ?? "")
        }
        return Text("\(drop.showName) · \(Text(timerInterval: moment.date...drop.date, pauseTime: drop.date, countsDown: true))")
    }
}
