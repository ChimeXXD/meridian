import SwiftUI
import WidgetKit

/// accessoryInline, the line above the Lock Screen clock: "Silo · 2d 4:10:22", live to the second (SPEC §5, Chime 1
/// Nov). The system draws it in its own font. The count is a ticking `Text(timerInterval:countsDown:)` to
/// the next day edge, which stops at zero (CLAUDE.md rule 4); the hourly entries step the days down, and the entry at
/// the drop says "Silo · Out now".
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
        // Only a live count has no static text, and it always has a current drop.
        if let text = WidgetText.inline(moment, formatter: formatter) { return Text(text) }
        guard let drop = moment.current else { return Text(verbatim: "") }
        let split = CountdownFormatter.daySplit(drop: drop.date, now: moment.date)
        // No `pauseTime`: it freezes the timer in widgets (see CountdownText).
        let timer = Text(timerInterval: moment.date...split.edge, countsDown: true)
        return split.days > 0
            ? Text("\(drop.showName) · \(split.days)d \(timer)")
            : Text("\(drop.showName) · \(timer)")
    }
}
