import SwiftUI
import WidgetKit

/// accessoryCircular: a big "2d" / "4h" / "38m" (bright number, dim unit, #135 Waymo) inside a ring that fills over the
/// last 7 days (SPEC §5). Out now is a full ring and "Out"; a date-only drop is a calendar glyph and its day number with
/// no ring; nothing followed is the empty ring (UI-BRIEF §6.1). The value is static, so `WidgetTimeline` adds an entry
/// every hour, and every 5 minutes in the last hour.
struct CircularWidgetView: View {
    let moment: WidgetMoment
    var formatter = DropFormatter()

    nonisolated static let ringSpan: TimeInterval = 7 * 86_400
    private let lineWidth: CGFloat = 4.5

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        ZStack {
            if moment.state != .dateOnly { ring }
            value.accessibilityIdentifier("widget-circular-value")
        }
        .padding(lineWidth / 2)
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetAccessibility.label(for: moment.spokenDrop, now: moment.date, formatter: formatter))
    }

    /// How full the ring is: empty a week or more out, full at the drop.
    nonisolated static func progress(to drop: Date, now: Date) -> Double {
        min(1, max(0, 1 - drop.timeIntervalSince(now) / ringSpan))
    }

    private var ring: some View {
        let filled: Double = switch moment.state {
        case .outNow: 1
        case .countingDown: moment.current.map { Self.progress(to: $0.date, now: moment.date) } ?? 0
        case .dateOnly, .nothing: 0
        }
        return ZStack {
            Circle().stroke(Color.primary.opacity(dimmed ? 0.15 : 0.25), lineWidth: lineWidth)
            Circle().trim(from: 0, to: filled)
                .stroke(Color.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
        }
        .accessibilityIdentifier("widget-circular-ring")
    }

    @ViewBuilder private var value: some View {
        switch moment.state {
        case .countingDown:
            if let drop = moment.current,
               let part = CountdownFormatter.parts(from: moment.date, to: drop.date, maxUnits: 1).first {
                Text("\(Text(verbatim: "\(part.value)").font(numerals(24)))\(Text(verbatim: part.unit.rawValue).font(numerals(13)).foregroundStyle(.secondary))")
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .widgetAccentable()
            }
        case .outNow:
            Text("Out").font(numerals(19)).widgetAccentable()
        case .dateOnly:
            VStack(spacing: 0) {
                Image(systemName: "calendar").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                Text(verbatim: dayNumber).font(numerals(22)).widgetAccentable()
            }
        case .nothing:
            EmptyView()
        }
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
