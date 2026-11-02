import SwiftUI
import WidgetKit

/// accessoryInline, the line above the Lock Screen clock: "Silo · 2d 4h" more than a day away, stepped down by the
/// hourly entries, then live to the second in the last day (SPEC §5, Chime 2 Nov). The system draws it in its own
/// font. The live count is a `Text(timerInterval:countsDown:)` to the drop, which stops at zero (CLAUDE.md rule 4),
/// and the entry at the drop says "Silo · Out now".
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
        // Only the last day's live count has no static text, and it always has a current drop.
        if let text = WidgetText.inline(moment, formatter: formatter) { return Text(text) }
        guard let drop = moment.current else { return Text(verbatim: "") }
        // No `pauseTime`: it freezes the timer in widgets (see CountdownText).
        return Text("\(drop.showName) · \(Text(timerInterval: moment.date...drop.date, countsDown: true))")
    }
}
