import SwiftUI
import WidgetKit

/// The countdown for one drop. Within 24 hours it ticks with `Text(timerInterval:pauseTime:countsDown:)`,
/// so it stops at zero and never counts up (CLAUDE.md rule 4). Further out it shows "2d 4h" with the
/// digits bright and the units dim (UI-BRIEF §1.3). A `dateOnly` drop shows its airdate, never a timer.
/// The caller owns `now` and must refresh it: widgets pass their timeline entry's date (with an entry at
/// the drop, SPEC §5); app screens wrap the list in a `TimelineView` (Day 3), or "Out now" never appears.
struct CountdownText: View {
    let drop: Date
    let confidence: Confidence
    var airdate: String?
    let now: Date
    var size: CGFloat = 34
    var tint: Color = .primary
    var formatter = DropFormatter()

    @Environment(\.numeralStudy) private var study
    @ScaledMetric private var scale: CGFloat = 1

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
            Text(airdate.flatMap(formatter.airdate) ?? "Date not set")
                .font(study.font(size: size * 0.6 * scale))
        case .outNow:
            Text("Out now").font(study.font(size: size * 0.7 * scale))
        case .released:
            Text("Released").font(study.font(size: size * 0.6 * scale)).foregroundStyle(.secondary)
        case .ticking:
            Text(timerInterval: now...drop, pauseTime: drop, countsDown: true)
                .font(study.font(size: size * scale))
        case .coarse(let parts):
            coarse(parts).accessibilityLabel(CountdownFormatter.spokenText(parts))
        }
    }

    private func coarse(_ parts: [CountdownPart]) -> Text {
        let digits = study.font(size: size * scale)
        let units = study.font(size: size * 0.5 * scale)
        return parts.enumerated().reduce(Text(verbatim: "")) { text, item in
            let gap = item.offset == 0 ? "" : " "
            return Text("\(text)\(gap)\(Text(verbatim: "\(item.element.value)").font(digits))\(Text(verbatim: item.element.unit.rawValue).font(units).foregroundStyle(.secondary))")
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
