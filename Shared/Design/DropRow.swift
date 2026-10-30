import SwiftUI

/// One drop in a list: what, when (local), how long, where the time came from and where to watch.
/// A moved time shows "Delayed" with the old time struck through (#43 Qantas).
struct DropRow: View {
    let drop: Drop
    /// 1-based position, for test IDs (`drop-row-1`).
    let index: Int
    let now: Date
    var formatter = DropFormatter()

    var body: some View {
        HStack(alignment: .top, spacing: Tokens.Space.s) {
            VStack(alignment: .leading, spacing: 6) {
                Text(drop.showName)
                    .font(.headline)
                    .lineLimit(2)
                    .accessibilityIdentifier("\(testID)-title")
                Text(meta)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("\(testID)-time")
                if let previous = drop.previousDate {
                    delayed(from: previous)
                }
                // One line when it fits; otherwise the provider wraps under the chip so it's never cut off.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Tokens.Space.xs) {
                        SourceChip(source: drop.source, confidence: drop.confidence)
                        ProviderLabelView(provider: drop.provider).fixedSize()
                    }
                    VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                        SourceChip(source: drop.source, confidence: drop.confidence)
                        ProviderLabelView(provider: drop.provider).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Spacer(minLength: Tokens.Space.s)
            // The countdown is short; it keeps its full size and the text column wraps instead.
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                          size: 28, formatter: formatter)
                .fixedSize()
        }
        .padding(Tokens.Space.m)
        .background(Tokens.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(testID)
    }

    private var testID: String { "drop-row-\(index)" }

    /// "S2E5 · Tomorrow 02:00", or "S2E5 · time not announced" for a date-only drop.
    private var meta: String {
        let when = drop.confidence == .dateOnly
            ? "time not announced"
            : "\(formatter.relativeDay(drop.date, now: now)) \(formatter.localTime(drop.date))"
        return [drop.episodeLabel, when].compactMap(\.self).joined(separator: " · ")
    }

    private func delayed(from previous: Date) -> some View {
        // A delay past midnight names the old day too, so "02:00" struck through isn't mistaken for today's.
        let old = formatter.localDay(previous) == formatter.localDay(drop.date)
            ? formatter.localTime(previous)
            : formatter.weekdayTime(previous)
        return HStack(spacing: Tokens.Space.xs) {
            Label("Delayed", systemImage: "arrow.uturn.forward")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(uiColor: Tokens.Ink.delayed))
            Text(old)
                .font(.caption)
                .strikethrough()
                .foregroundStyle(.secondary)
                .accessibilityLabel("was \(old)")
        }
    }
}

#Preview("Rows") {
    let now = Date.now
    let lagos = DropFormatter(zoneIdentifier: "Africa/Lagos")
    ScrollView {
        VStack(spacing: Tokens.Space.s) {
            ForEach(Array(DropRow.samples(now: now).enumerated()), id: \.offset) { item in
                DropRow(drop: item.element, index: item.offset + 1, now: now, formatter: lagos)
            }
        }
        .padding()
    }
    .background(Tokens.background)
}

extension DropRow {
    /// Realistic sample drops for previews and the numeral studies. No poster art, ever.
    static func samples(now: Date) -> [Drop] {
        func drop(_ id: String, _ name: String, _ season: Int?, _ number: Int?, in seconds: TimeInterval,
                  _ confidence: Confidence, _ source: ReleaseSource, _ provider: ProviderLabel?,
                  airdate: String? = nil, delayedBy: TimeInterval? = nil) -> Drop {
            let date = now.addingTimeInterval(seconds)
            return Drop(id: "tvmaze:\(id)", showID: id, showName: name, season: season, number: number, episodeTitle: nil,
                        date: date, airdate: airdate, confidence: confidence, source: source, provider: provider,
                        previousDate: delayedBy.map { date.addingTimeInterval(-$0) })
        }
        return [
            drop("1", "Silo", 3, 1, in: 2 * 3_600 + 600, .exact, .broadcast(network: "Apple TV"),
                 ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false)),
            drop("2", "Frieren: Beyond Journey's End", 2, 8, in: 5 * 3_600 + 1_500, .exact, .anilist,
                 ProviderLabel(name: "Crunchyroll", countryCode: nil, noOfficialStream: false)),
            drop("3", "House of the Dragon", 3, 4, in: 2 * 86_400 + 4 * 3_600, .exact, .broadcast(network: "HBO"),
                 ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: true)),
            drop("4", "Stranger Things", 5, 5, in: 3 * 86_400 + 7_200, .estimated, .platformRule("Netflix rule"),
                 ProviderLabel(name: "Netflix", countryCode: nil, noOfficialStream: false), delayedBy: 3_600),
            drop("5", "The Bear", 5, 1, in: 12 * 86_400, .dateOnly, .dateOnly,
                 ProviderLabel(name: "FX", countryCode: "US", noOfficialStream: false), airdate: "2026-11-11"),
        ]
    }
}
