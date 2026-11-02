import SwiftUI
import WidgetKit

/// The countdown for one drop. Only the last day ticks (Chime, 2 Nov): from 24 hours out it is a live
/// `Text(timerInterval:countsDown:)` with no `pauseTime` (D-52), so it stops at zero and never counts up (CLAUDE.md
/// rule 4). Further out it stands still at whole days and hours, units smaller and dim: "4d 4h"
/// (`CountdownFormatter.stillParts`). A `dateOnly` drop shows its airdate, never a timer. The timer is sized from
/// `CountdownFormatter.clockTemplate`, because in a widget a ticking text otherwise takes all the width it's offered
/// and pushes the rest out (the medium widget went blank, 1 Nov).
/// The caller owns `now` and must refresh it: widgets pass their timeline entry's date (with an entry at the drop and
/// on every hour, SPEC §5); app screens wrap it in `TimelineView(.countdown)`, or "Out now" never appears. The
/// timeline also paces the ticking text, so a slower one (`.everyMinute`) freezes the count between its entries.
struct CountdownText: View {
    let drop: Date
    let confidence: Confidence
    var airdate: String?
    let now: Date
    var size: CGFloat = 34
    var tint: Color = .primary
    var formatter = DropFormatter()
    /// Where the digits sit inside the template's width: trailing in right-aligned columns.
    var alignment: Alignment = .leading

    @Environment(\.numeralStudy) private var study
    @ScaledMetric private var scale: CGFloat = 1
    /// Gold only in full colour: tinted, clear and Lock Screen renderings keep the system's tint (D-53).
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        content
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .widgetAccentable()  // the one element that takes the tint in accented widgets
            .accessibilityIdentifier("countdown")
    }

    @ViewBuilder private var content: some View {
        switch CountdownFormatter.state(drop: drop, confidence: confidence, now: now) {
        case .dateOnly:
            Text(airdate.flatMap { formatter.airdate($0, now: now) } ?? "Date not set")
                .font(study.font(size: size * 0.6 * scale))
        case .outNow:
            Text("Out now").font(study.font(size: size * 0.7 * scale))
                .foregroundStyle(renderingMode == .fullColor ? Color(uiColor: Tokens.gold) : tint)
        case .released:
            Text("Released").font(study.font(size: size * 0.6 * scale)).foregroundStyle(.secondary)
        case .ticking:
            live
        case .coarse(let parts):
            still(parts).accessibilityLabel(CountdownFormatter.spokenText(parts))
        }
    }

    private var textAlignment: TextAlignment {
        switch alignment.horizontal {
        case .trailing: .trailing
        case .center: .center
        default: .leading
        }
    }

    private var digits: Font { study.font(size: size * scale).monospacedDigit() }

    /// The last day's live count, inside a hidden template as wide as its widest value.
    private var live: some View {
        Text(verbatim: CountdownFormatter.clockTemplate(drop: drop, now: now))
            .font(digits)
            .hidden()
            .overlay(alignment: alignment) {
                // No `pauseTime`: with one, WidgetKit draws the timer frozen at its first value (seen in the
                // simulator's Dynamic Island, 1 Nov). The interval alone stops at 0:00 and never counts up (rule 4).
                Text(timerInterval: now...drop, countsDown: true)
                    .font(digits)
                    .multilineTextAlignment(textAlignment)
            }
    }

    /// "4d 4h" more than a day away: bright digits, the unit letters smaller and dim. Static text, so it needs no
    /// template; the caller's `now` steps it (hourly widget entries, the app's per-second redraw).
    private func still(_ parts: [CountdownPart]) -> Text {
        let unit = study.font(size: size * 0.5 * scale)
        return parts.enumerated().reduce(Text(verbatim: "")) { text, item in
            let gap = Text(verbatim: item.offset == 0 ? "" : " ").font(unit)
            let value = Text(verbatim: "\(item.element.value)").font(digits)
            let letter = Text(verbatim: item.element.unit.rawValue).font(unit).foregroundStyle(.secondary)
            return Text("\(text)\(gap)\(value)\(letter)")
        }
    }
}

#Preview("States") {
    let now = Date.now
    VStack(alignment: .trailing, spacing: Tokens.Space.m) {
        CountdownText(drop: now.addingTimeInterval(2 * 86_400 + 4 * 3_600), confidence: .exact, now: now)
        CountdownText(drop: now.addingTimeInterval(2 * 3_600 + 600), confidence: .exact, now: now)
        CountdownText(drop: now.addingTimeInterval(-600), confidence: .exact, now: now)
        CountdownText(drop: now, confidence: .dateOnly, airdate: "2026-11-11", now: now)
    }
    .padding()
}
