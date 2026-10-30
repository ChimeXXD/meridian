#if DEBUG
import SwiftUI

/// Direction B, Glass: the next show's art, blurred, is the whole background, and the screen reads like Apple
/// Weather. Each show is a card over its own art with a large thin countdown where Weather puts the temperature,
/// and its time sits in a Liquid Glass strip; a glass search bar floats at the bottom (picks: TIDE, Insight Timer's
/// glass button, Apple TV and Spotify widgets).
struct GlassUpcoming: View {
    let drops: [Drop]
    let artwork: [String: ShowArtwork]
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil
    var onSelect: (Drop) -> Void = { _ in }

    var body: some View {
        TimelineView(.everyMinute) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.s) {
                    header
                    ForEach(Array(drops.enumerated()), id: \.element.id) { index, drop in
                        Button { onSelect(drop) } label: {
                            GlassCard(drop: drop, artwork: artwork[drop.showID], index: index + 1, featured: index == 0,
                                      now: context.date, formatter: formatter)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Tokens.Space.m)
                .padding(.bottom, Tokens.Space.l)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(scrollAnchor)
            .safeAreaInset(edge: .bottom) { searchBar }
            .background { backdrop }
        }
        .environment(\.colorScheme, .dark)
    }

    private var backdrop: some View {
        ArtworkLoaderView(url: drops.first.flatMap { artwork[$0.showID]?.hero }, maxPixel: 600) { hero in
            ArtworkFill(image: hero?.image, palette: hero?.palette ?? .neutral)
                .blur(radius: 50)
                .overlay(Color.black.opacity(0.4))
        }
        .background(.black)
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Upcoming").font(.largeTitle.weight(.bold))
                Text("Times in Lagos · WAT")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .accessibilityIdentifier("upcoming-zone")
            }
            Spacer()
            GlassCircleButton(systemImage: "ellipsis", label: "More") {}
        }
        .padding(.top, Tokens.Space.s)
        .padding(.bottom, Tokens.Space.xs)
    }

    private var searchBar: some View {
        GlassEffectContainer(spacing: Tokens.Space.s) {
            HStack(spacing: Tokens.Space.s) {
                Label("Search shows and anime", systemImage: "magnifyingglass")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Tokens.Space.m)
                    .frame(height: 50)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .accessibilityIdentifier("upcoming-search")
                GlassCircleButton(systemImage: "gearshape", label: "Settings", size: 50) {}
            }
        }
        .padding(.horizontal, Tokens.Space.m)
        .padding(.bottom, Tokens.Space.xs)
    }
}

/// One show as an Apple Weather city card, over its own art.
struct GlassCard: View {
    let drop: Drop
    let artwork: ShowArtwork?
    /// 1-based, for test IDs.
    let index: Int
    var featured = false
    let now: Date
    var formatter = DropFormatter()

    var body: some View {
        ArtworkLoaderView(url: artwork?.hero, maxPixel: 900) { loaded in
            VStack(alignment: .leading, spacing: 0) {
                // Weather's layout: the name on the left, the number on the right. The featured card has room to
                // put the number on its own line, as large as Weather's city detail.
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(drop.showName)
                            .font(featured ? .title2.weight(.bold) : .title3.weight(.bold))
                            .lineLimit(2)
                            .accessibilityIdentifier("drop-row-\(index)-title")
                        Text(DirectionCopy.episodeAndProvider(drop))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    if !featured {
                        Spacer(minLength: Tokens.Space.s)
                        countdown(size: 38).fixedSize()
                    }
                }
                if featured {
                    countdown(size: 76).padding(.top, Tokens.Space.xxs)
                }
                Spacer(minLength: Tokens.Space.s)
                HStack(spacing: Tokens.Space.xs) {
                    Text(DirectionCopy.yourTime(drop, now: now, formatter: formatter))
                        .font(.subheadline.weight(.semibold))
                        .accessibilityIdentifier("drop-row-\(index)-time")
                    Spacer(minLength: Tokens.Space.xs)
                    SourceChip(source: drop.source, confidence: drop.confidence)
                }
                .padding(.leading, Tokens.Space.s).padding(.trailing, 6).padding(.vertical, 6)
                .glassEffect(.regular, in: .capsule)
            }
            .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
            .padding(Tokens.Space.m)
            .frame(height: featured ? 230 : 150)
            .background {
                ArtworkFill(image: loaded?.image, palette: loaded?.palette ?? .neutral)
                    .overlay(LinearGradient(colors: [.black.opacity(0.5), .black.opacity(0.1), .black.opacity(0.35)],
                                            startPoint: .top, endPoint: .bottom))
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.25)))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("drop-row-\(index)")
    }

    private func countdown(size: CGFloat) -> some View {
        CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                      size: size, tint: .white, formatter: formatter)
            .environment(\.numeralStudy, .glass)
    }
}
#endif
