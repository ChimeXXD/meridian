import SwiftUI

/// One numeral study (UI-BRIEF §3) drawn across every surface, so Chime can compare A, B and C side by side.
/// The widget and Live Activity frames are faithful mock-ups at their real point sizes; the real WidgetKit
/// views come on Day 4. Deleted once a study is picked.
struct NumeralStudyBoard: View {
    let study: NumeralStudy
    let now: Date
    var formatter = DropFormatter(zoneIdentifier: "Africa/Lagos")

    @Environment(\.colorScheme) private var scheme

    private var drops: [Drop] { DropRow.samples(now: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text(study.title).font(.largeTitle.weight(.bold))
                Text("\(study.summary) · \(scheme == .dark ? "dark" : "light")")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            panel("Upcoming hero") { hero }
            panel("Lock Screen") {
                StudyLockScreen(next: drops[0], later: drops[2], now: now, formatter: formatter)
            }
            panel("Dynamic Island") { StudyDynamicIsland(drop: drops[0], now: now, formatter: formatter) }
            panel("Home Screen") {
                VStack(alignment: .leading, spacing: Tokens.Space.m) {
                    HStack(spacing: Tokens.Space.m) {
                        StudySmallWidget(drop: drops[0], now: now)
                        StudySmallWidget(drop: drops[2], now: now)
                    }
                    StudyMediumWidget(drops: Array(drops.prefix(3)), now: now, formatter: formatter)
                }
            }
            panel("Upcoming rows") {
                VStack(spacing: Tokens.Space.s) {
                    SectionHeader(id: "this-week", title: "This week", count: 3)
                    ForEach([2, 3, 4], id: \.self) { index in
                        DropRow(drop: drops[index], index: index + 1, now: now, formatter: formatter)
                    }
                }
            }
        }
        .padding(Tokens.Space.l)
        .frame(width: 440)
        .background(Tokens.background)
        .environment(\.numeralStudy, study)
    }

    /// The single nearest drop, large (#62 Fixtured): relative day, huge local time, countdown, chip, provider.
    private var hero: some View {
        let drop = drops[0]
        return VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("NEXT UP · \(formatter.relativeDay(drop.date, now: now).uppercased())")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(formatter.localTime(drop.date))
                .font(study.font(size: 72))
                .lineLimit(1).minimumScaleFactor(0.5)
            Text([drop.showName, drop.episodeLabel].compactMap(\.self).joined(separator: " · "))
                .font(.title3.weight(.semibold))
            HStack(spacing: Tokens.Space.xs) {
                Text("in").foregroundStyle(.secondary)
                CountdownText(drop: drop.date, confidence: drop.confidence, now: now, size: 22, tint: study.accent)
            }
            HStack(spacing: Tokens.Space.xs) {
                SourceChip(source: drop.source, confidence: drop.confidence)
                ProviderLabelView(provider: drop.provider)
            }
        }
        .padding(Tokens.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
    }

    private func panel(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text(title.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            content()
        }
    }
}

#Preview("A · System") { NumeralStudyBoard(study: .system, now: .now) }
#Preview("B · Mono") { NumeralStudyBoard(study: .mono, now: .now).preferredColorScheme(.dark) }
#Preview("C · Serif") { NumeralStudyBoard(study: .serif, now: .now) }
