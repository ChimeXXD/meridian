#if DEBUG
import SwiftUI

/// Night Sky Upcoming (D-38): the next show's art fades into night, then three lines answer the only question,
/// how long, when, and where. Everything after it is one quiet list in SPEC's sections. No player controls, no
/// progress bar, nothing that isn't about the next episode (Chime: "make it much cleaner").
struct NightSkyUpcoming: View {
    let drops: [Drop]
    let artwork: [String: ShowArtwork]
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil
    var onSelect: (Drop) -> Void = { _ in }

    var body: some View {
        TimelineView(.everyMinute) { context in
            ArtworkLoaderView(url: drops.first.flatMap { artwork[$0.showID]?.hero },
                              maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
                let base = (hero?.palette ?? .neutral).night.color
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        if let next = drops.first {
                            Button { onSelect(next) } label: {
                                NightSkyHero(drop: next, image: hero?.image, base: base, now: context.date, formatter: formatter)
                            }
                            .buttonStyle(.plain)
                        }
                        VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                            ForEach(UpcomingArtView.sections(after: drops, now: context.date), id: \.title) { section in
                                VStack(alignment: .leading, spacing: Tokens.Space.s) {
                                    Text(section.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .accessibilityAddTraits(.isHeader)
                                    VStack(alignment: .leading, spacing: Tokens.Space.l) {
                                        ForEach(section.drops) { drop in row(drop, now: context.date) }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Tokens.Space.l)
                    }
                    .padding(.bottom, Tokens.Space.xl)
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(scrollAnchor)
                .background(base)
                .overlay(alignment: .top) { StatusBarScrim(color: base) }
                .ignoresSafeArea(edges: .top)
            }
        }
        .environment(\.colorScheme, .dark)
    }

    /// One row: art, then the same three facts as the hero, smaller; the countdown on the right.
    private func row(_ drop: Drop, now: Date) -> some View {
        // The hero is drops[0], so the rows number 1...n as in UI-BRIEF.
        let index = drops.firstIndex { $0.id == drop.id } ?? 0
        return Button { onSelect(drop) } label: {
            HStack(spacing: Tokens.Space.m) {
                ArtworkLoaderView(url: artwork[drop.showID]?.hero, maxPixel: 300) { loaded in
                    ArtworkFill(image: loaded?.image, palette: .neutral)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    // The countdown sits beside the title only, so the meta line below gets the full width.
                    HStack(alignment: .firstTextBaseline) {
                        Text(drop.showName)
                            .font(.system(size: 20, design: .serif))
                            .lineLimit(2)
                            .accessibilityIdentifier("drop-row-\(index)-title")
                        Spacer(minLength: Tokens.Space.xs)
                        if drop.confidence != .dateOnly {  // a date-only drop's date is already in the out line
                            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                                          size: 24, tint: .white, formatter: formatter)
                                .environment(\.numeralStudy, .night)
                                .fixedSize()
                        }
                    }
                    Text(DirectionCopy.outLine(drop, now: now, formatter: formatter))
                        .font(.subheadline)
                        .foregroundStyle(NightInk.secondary)
                        .accessibilityIdentifier("drop-row-\(index)-time")
                    NightSkyMeta(drop: drop)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("drop-row-\(index)")
    }

}

/// The next drop: art on top fading into night, then the title, a giant light serif countdown, when it's out,
/// and the episode, provider and source on one quiet line.
struct NightSkyHero: View {
    let drop: Drop
    let image: UIImage?
    let base: Color
    let now: Date
    var formatter = DropFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                ArtworkFill(image: image, palette: .neutral).frame(height: 472)
                LinearGradient(stops: [.init(color: base.opacity(0), location: 0.4), .init(color: base, location: 1)],
                               startPoint: .top, endPoint: .bottom)
                LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.25))
            }
            .frame(height: 472)
            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                NightSkyHeadline(drop: drop, now: now, formatter: formatter, titleSize: 32, countdownSize: 88,
                                 testID: "upcoming-hero")
                NightSkyMeta(drop: drop)
            }
            .padding(.horizontal, Tokens.Space.l)
            .padding(.top, -64)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("upcoming-hero")
    }
}

/// Title, countdown, and when it's out: the three lines that answer the question.
struct NightSkyHeadline: View {
    let drop: Drop
    let now: Date
    var formatter = DropFormatter()
    var titleSize: CGFloat = 32
    var countdownSize: CGFloat = 88
    /// Prefix for the test IDs: `upcoming-hero` or `detail` (UI-BRIEF).
    var testID = "headline"

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Text(drop.showName)
                .font(.system(size: titleSize, design: .serif))
                .lineLimit(2).minimumScaleFactor(0.7)
                .accessibilityIdentifier("\(testID)-title")
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                          size: countdownSize, tint: .white, formatter: formatter)
                .environment(\.numeralStudy, .night)
            Text(DirectionCopy.outLine(drop, now: now, formatter: formatter, naming: true))
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
                .padding(.top, Tokens.Space.xxs)
                .accessibilityIdentifier("\(testID)-out")
        }
    }
}

/// "S4E1 · Apple TV" in muted text, then the time's certainty in words for the chosen `TrustStyle`: nothing in A
/// (the out line says it), a flag on the exceptions in B, the source named in C.
struct NightSkyMeta: View {
    let drop: Drop
    var style: TrustStyle = .launched

    var body: some View {
        HStack(spacing: Tokens.Space.xs) {
            Text(style == .sourced
                 ? "\(DirectionCopy.episodeAndProvider(drop)) · \(DirectionCopy.sourcePhrase(drop))"
                 : DirectionCopy.episodeAndProvider(drop))
                .font(.footnote)
                .foregroundStyle(NightInk.muted)
                .lineLimit(1)
            if style == .flagged, let flag = DirectionCopy.flag(drop) {
                Text(flag)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(NightInk.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(Capsule().strokeBorder(NightInk.primary.opacity(0.35)))
                    .fixedSize()  // the episode and provider truncate first, never the flag
                    .accessibilityIdentifier("trust-flag")
            }
        }
    }
}
#endif
