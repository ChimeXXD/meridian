#if DEBUG
import SwiftUI

/// Direction A, Night Sky: Insight Timer's player as the home screen. The next show's art sinks into a quiet dark
/// base taken from it, under a giant light serif countdown; later shows sit on Insight Timer's photo-card shelf and
/// serif list (picks: Insight Timer, Apple Music, HBO Max).
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
                let base = (hero?.palette ?? .neutral).muted.color
                ScrollView {
                    VStack(alignment: .leading, spacing: 36) {
                        if let next = drops.first {
                            Button { onSelect(next) } label: {
                                NightSkyHero(drop: next, image: hero?.image, base: base, now: context.date, formatter: formatter)
                            }
                            .buttonStyle(.plain)
                        }
                        let later = drops.dropFirst()
                        let isSoon = { (drop: Drop) in
                            drop.confidence != .dateOnly && drop.date.timeIntervalSince(context.date) <= 7 * 86_400
                        }
                        let soon = later.filter(isSoon)
                        if !soon.isEmpty { shelf(soon, now: context.date) }
                        let rest = later.filter { !isSoon($0) }
                        if !rest.isEmpty { list(rest, now: context.date) }
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

    /// Insight Timer's "Preset Library" shelf: tall photo cards, serif titles under them.
    private func shelf(_ items: [Drop], now: Date) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            Text("This week")
                .font(.system(size: 26, design: .serif))
                .padding(.horizontal, Tokens.Space.l)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Tokens.Space.s) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, drop in
                        Button { onSelect(drop) } label: { card(drop, index: index + 1, now: now) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Tokens.Space.l)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func card(_ drop: Drop, index: Int, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ArtworkLoaderView(url: artwork[drop.showID]?.hero, maxPixel: 700) { loaded in
                ArtworkFill(image: loaded?.image, palette: .neutral)
                    .frame(width: 164, height: 210)
                    .overlay { LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom) }
                    .overlay(alignment: .bottomLeading) {
                        CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                                      size: 30, tint: .white, formatter: formatter)
                            .environment(\.numeralStudy, .night)
                            .padding(10)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Text("\(DirectionCopy.yourTime(drop, now: now, formatter: formatter)) · \(drop.provider?.display ?? "")")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
            Text(drop.showName)
                .font(.system(size: 18, design: .serif))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("drop-card-\(index)-title")
            SourceChip(source: drop.source, confidence: drop.confidence)
        }
        .frame(width: 164, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("drop-card-\(index)")
    }

    /// Insight Timer's library list: square photo, small meta line, serif title.
    private func list(_ items: [Drop], now: Date) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.m) {
            Text("Later")
                .font(.system(size: 26, design: .serif))
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(items.enumerated()), id: \.element.id) { index, drop in
                Button { onSelect(drop) } label: {
                    HStack(spacing: 14) {
                        ArtworkLoaderView(url: artwork[drop.showID]?.hero, maxPixel: 300) { loaded in
                            ArtworkFill(image: loaded?.image, palette: .neutral)
                                .frame(width: 76, height: 76)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(DirectionCopy.yourTime(drop, now: now, formatter: formatter)) · \(drop.provider?.display ?? "")")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                            Text(drop.showName).font(.system(size: 19, design: .serif)).lineLimit(2)
                            SourceChip(source: drop.source, confidence: drop.confidence)
                        }
                        Spacer(minLength: Tokens.Space.xs)
                        CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                                      size: 26, tint: .white, formatter: formatter)
                            .environment(\.numeralStudy, .night)
                            .fixedSize()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("drop-row-\(index + 1)")
            }
        }
        .padding(.horizontal, Tokens.Space.l)
    }
}

/// The next drop as Insight Timer's player: art on top, the muted base below, a giant light serif countdown with
/// quiet controls beside it, a thin bar for the last week before the drop, then the serif title.
struct NightSkyHero: View {
    let drop: Drop
    let image: UIImage?
    let base: Color
    let now: Date
    var formatter = DropFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                ArtworkFill(image: image, palette: .neutral).frame(height: 460)
                LinearGradient(stops: [.init(color: base.opacity(0), location: 0.4), .init(color: base, location: 1)],
                               startPoint: .top, endPoint: .bottom)
                LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.25))
                Text("Times in Lagos · WAT")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, Tokens.Space.s).padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.leading, Tokens.Space.l).padding(.top, 62)
                    .accessibilityIdentifier("upcoming-zone")
            }
            .frame(height: 460)
            NightSkyPlayer(drop: drop, now: now, formatter: formatter, countdownSize: 84)
                .padding(.horizontal, Tokens.Space.l)
                .padding(.top, -36)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("upcoming-hero")
    }
}

/// The lower half of Insight Timer's player, shared by the Upcoming hero and Show detail.
struct NightSkyPlayer: View {
    let drop: Drop
    let now: Date
    var formatter = DropFormatter()
    var countdownSize: CGFloat = 84
    var showTitle = true
    /// Show detail has the big glass bell instead.
    var showControls = true

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            HStack(alignment: .center) {
                CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                              size: countdownSize, tint: .white, formatter: formatter)
                    .environment(\.numeralStudy, .night)
                Spacer(minLength: Tokens.Space.s)
                if showControls {
                    Image(systemName: "bell").accessibilityLabel("Live Activity on")
                    Image(systemName: "ellipsis").padding(.leading, Tokens.Space.m).accessibilityLabel("More")
                }
            }
            .font(.title3)
            .foregroundStyle(.white.opacity(0.85))
            bar
            if showTitle {
                Text(drop.showName)
                    .font(.system(size: 32, design: .serif))
                    .lineLimit(2)
                    .padding(.top, Tokens.Space.xs)
                    .accessibilityIdentifier("upcoming-hero-title")
            }
            Text(DirectionCopy.episodeAndProvider(drop))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
            SourceChip(source: drop.source, confidence: drop.confidence)
        }
    }

    /// Fills over the week before the drop, like the track bar under Insight Timer's timer.
    private var bar: some View {
        let fraction = drop.confidence == .dateOnly ? 0 : min(max(1 - drop.date.timeIntervalSince(now) / (7 * 86_400), 0), 1)
        return VStack(spacing: 6) {
            HStack {
                Text("Now")
                Spacer()
                Text("\(DirectionCopy.yourTime(drop, now: now, formatter: formatter)) your time")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.6))
            Capsule().fill(.white.opacity(0.16)).frame(height: 5)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in Capsule().fill(.white.opacity(0.85)).frame(width: geo.size.width * fraction) }
                }
                .accessibilityHidden(true)
        }
    }
}
#endif
