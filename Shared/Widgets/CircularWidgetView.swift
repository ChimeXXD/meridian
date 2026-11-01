import SwiftUI
import WidgetKit

/// accessoryCircular, after #Udemy: an open ring, a TV glyph in the middle saying what's counted, and the count in the
/// gap at the bottom: "2d", "4h", "38m" (bright number, dim unit, #135 Waymo). The ring fills over the last 7 days
/// (SPEC §5). Out now is a full gauge and "Out"; a date-only drop is a calendar glyph and
/// its day number with no gauge; nothing followed is the empty gauge (UI-BRIEF §6.1). The value is static, so
/// `WidgetTimeline` adds an entry every hour, and every 5 minutes in the last hour.
struct CircularWidgetView: View {
    let moment: WidgetMoment
    var formatter = DropFormatter()

    nonisolated static let ringSpan: TimeInterval = 7 * 86_400

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        Group {
            if moment.state == .dateOnly { dateOnly } else { gauge }
        }
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetAccessibility.label(for: moment.spokenDrop, now: moment.date, formatter: formatter))
    }

    /// How far along the gauge is: empty a week or more out, full at the drop.
    nonisolated static func progress(to drop: Date, now: Date) -> Double {
        min(1, max(0, 1 - drop.timeIntervalSince(now) / ringSpan))
    }

    private var filled: Double {
        switch moment.state {
        case .outNow: 1
        case .countingDown: moment.current.map { Self.progress(to: $0.date, now: moment.date) } ?? 0
        case .dateOnly, .nothing: 0
        }
    }

    /// Drawn rather than the system's `.accessoryCircular` gauge, which keeps the whole arc bright and only moves a dot,
    /// so an empty week would read as full.
    private var gauge: some View {
        ZStack {
            Group {
                arc(Self.arcSpan).stroke(Color.primary.opacity(dimmed ? 0.15 : 0.25), style: stroke)
                arc(Self.arcSpan * filled).stroke(Color.primary, style: stroke).widgetAccentable()
            }
            .padding(lineWidth / 2)
            .accessibilityIdentifier("widget-circular-ring")
            Image(systemName: "tv").font(.system(size: 17, weight: .semibold)).offset(y: -2)
            gapLabel
                .widgetAccentable()
                .frame(maxHeight: .infinity, alignment: .bottom)
                .accessibilityIdentifier("widget-circular-value")
        }
    }

    /// The share of a full circle the open ring covers; the rest is the gap at the bottom.
    private static let arcSpan = 0.75
    private let lineWidth: CGFloat = 4.5
    private var stroke: StrokeStyle { StrokeStyle(lineWidth: lineWidth, lineCap: .round) }

    /// A clockwise arc from the gap's left end (7:30 on a clock face), covering `share` of the circle.
    private func arc(_ share: Double) -> some Shape {
        Circle().trim(from: 0, to: share).rotation(.degrees(135))
    }

    @ViewBuilder private var gapLabel: some View {
        switch moment.state {
        case .countingDown:
            if let drop = moment.current,
               let part = CountdownFormatter.parts(from: moment.date, to: drop.date, maxUnits: 1).first {
                Text("\(Text(verbatim: "\(part.value)").font(numerals(14)))\(Text(verbatim: part.unit.rawValue).font(numerals(10)).foregroundStyle(.secondary))")
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        case .outNow:
            Text("Out").font(numerals(13))
        case .dateOnly, .nothing:
            EmptyView()
        }
    }

    private var dateOnly: some View {
        VStack(spacing: 0) {
            Image(systemName: "calendar").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            Text(verbatim: dayNumber).font(numerals(22)).widgetAccentable()
        }
        .accessibilityIdentifier("widget-circular-value")
    }

    /// The day of the month of a date-only drop's listed airdate ("11"), never shifted by zone (D-28).
    private var dayNumber: String {
        moment.current?.airdate.flatMap(WallClock.parseDate).map { "\($0.day)" } ?? "?"
    }

    /// Night Sky's serif numerals, a step heavier than the hero's light cut so they hold up at Lock Screen size.
    private func numerals(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif).monospacedDigit()
    }
}
