import SwiftUI
import WidgetKit

/// Day 0 placeholder: shows when the app last wrote to the shared App Group.
struct PlaceholderWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PlaceholderWidget", provider: PlaceholderProvider()) { entry in
            PlaceholderWidgetView(entry: entry)
        }
        .configurationDisplayName("Airstamp")
        .description("Setup check: reads what the app wrote.")
        .supportedFamilies([.systemSmall])
    }
}

struct PlaceholderEntry: TimelineEntry {
    let date: Date
    let appWroteAt: Date?
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: .now, appWroteAt: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> PlaceholderEntry {
        let wroteAt = AppGroup.defaults.flatMap { SetupCheck.read(from: $0) }
        return PlaceholderEntry(date: .now, appWroteAt: wroteAt)
    }
}

struct PlaceholderWidgetView: View {
    let entry: PlaceholderEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Airstamp")
                .font(.system(.headline, design: .rounded, weight: .bold))
            if let wroteAt = entry.appWroteAt {
                Text("App wrote at")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(wroteAt, style: .time)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .monospacedDigit()
            } else {
                Text("Open Airstamp once to finish setup.")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard let wroteAt = entry.appWroteAt else { return "Airstamp. Open the app once to finish setup." }
        return "Airstamp. The app last wrote shared data at \(wroteAt.formatted(date: .omitted, time: .shortened))."
    }
}

#Preview(as: .systemSmall) {
    PlaceholderWidget()
} timeline: {
    PlaceholderEntry(date: .now, appWroteAt: .now)
    PlaceholderEntry(date: .now, appWroteAt: nil)
}
