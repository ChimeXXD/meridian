#if DEBUG
import SwiftUI

/// Direction C, Show detail: the whole page is painted in the poster's colour (Paramount+, Deezer, Plex), with the
/// poster as a big card, a serif title and countdown, and translucent buttons and panels in the page's own ink.
struct PosterColourDetail: View {
    let drop: Drop
    let artwork: ShowArtwork?
    var episodes: [ShowDetailArtView.PastEpisode] = []
    var broadcastZone: String? = nil
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var liveActivity = true

    var body: some View {
        TimelineView(.everyMinute) { context in
            ArtworkLoaderView(url: artwork?.poster ?? artwork?.posterThumbnail, maxPixel: 900) { poster in
                let fill = (poster?.palette ?? .neutral).vivid
                ScrollView {
                    VStack(spacing: Tokens.Space.l) {
                        HStack {
                            GlassCircleButton(systemImage: "chevron.left", label: "Back") { dismiss() }
                            Spacer()
                            GlassCircleButton(systemImage: "square.and.arrow.up", label: "Share") {}
                        }
                        ArtworkFill(image: poster?.image, palette: poster?.palette ?? .neutral)
                            .frame(width: 200, height: 296)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.3), radius: 24, y: 14)
                        next(now: context.date, ink: fill.ink)
                        actions(ink: fill.ink)
                        card(ink: fill.ink) {
                            FactRows(rows: DirectionCopy.facts(drop, now: context.date, zone: broadcastZone, formatter: formatter), ink: fill.ink)
                        }
                        card(ink: fill.ink) {
                            Text("Episodes").font(.system(size: 22, weight: .semibold, design: .serif))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            EpisodeRows(episodes: episodes, ink: fill.ink, formatter: formatter)
                        }
                        Button("Report a wrong time") {}
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(fill.ink)
                            .accessibilityIdentifier("detail-report")
                    }
                    .padding(.horizontal, Tokens.Space.l)
                    .padding(.bottom, Tokens.Space.xl)
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(scrollAnchor)
                .background(fill.color)
                .foregroundStyle(fill.ink)
                .environment(\.colorScheme, fill.prefersWhiteText ? .dark : .light)
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private func next(now: Date, ink: Color) -> some View {
        VStack(spacing: Tokens.Space.xs) {
            Text(drop.showName)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("detail-title")
            Text(DirectionCopy.episodeAndProvider(drop))
                .font(.subheadline.weight(.semibold))
                .opacity(0.75)
                .accessibilityIdentifier("detail-network")
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                          size: 72, tint: ink, formatter: formatter)
                .environment(\.numeralStudy, .serif)
                .padding(.top, Tokens.Space.xs)
            Text("\(DirectionCopy.yourTime(drop, now: now, formatter: formatter)) your time")
                .font(.headline)
            SourceChip(source: drop.source, confidence: drop.confidence)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail-next")
    }

    private func actions(ink: Color) -> some View {
        HStack(spacing: Tokens.Space.s) {
            Button { liveActivity.toggle() } label: {
                Label(liveActivity ? "Live Activity on" : "Live Activity off",
                      systemImage: liveActivity ? "bell.fill" : "bell.slash")
                    .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("detail-live-activity")
            Button {} label: { Label("Follow", systemImage: "checkmark").frame(maxWidth: .infinity) }
        }
        .buttonStyle(.plain)
        .font(.subheadline.weight(.semibold))
        .labelStyle(.titleAndIcon)
        .frame(height: 48)
        .padding(.horizontal, 0)
        .background(ink.opacity(0.12), in: Capsule())
    }

    private func card<Content: View>(ink: Color, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs, content: content)
            .padding(Tokens.Space.m)
            .background(ink.opacity(0.1), in: RoundedRectangle(cornerRadius: 22))
    }
}
#endif
