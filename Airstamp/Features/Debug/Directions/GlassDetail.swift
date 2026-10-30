#if DEBUG
import SwiftUI

/// Direction B, Show detail: Insight Timer's ocean timer. The show's art fills the whole screen and stays put; the
/// countdown is centred on it, large and thin, and everything else floats over the art on Liquid Glass panels
/// (TIDE, Lumy's "Starts in" pill and fact table).
struct GlassDetail: View {
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
            ScrollView {
                VStack(spacing: Tokens.Space.m) {
                    topBar
                    centre(now: context.date)
                        .frame(minHeight: 470)
                    panel {
                        FactRows(rows: DirectionCopy.facts(drop, now: context.date, zone: broadcastZone, formatter: formatter), ink: .white)
                        HStack {
                            Text("Source").font(.subheadline).foregroundStyle(.white.opacity(0.7))
                            Spacer()
                            SourceChip(source: drop.source, confidence: drop.confidence)
                        }
                        .padding(.top, Tokens.Space.xs)
                    }
                    panel {
                        Toggle(isOn: $liveActivity) {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("Release-night Live Activity", systemImage: "bell.badge").font(.headline)
                                Text("Starts 2 hours before, on your Lock Screen")
                                    .font(.footnote).foregroundStyle(.white.opacity(0.75))
                            }
                        }
                        .accessibilityIdentifier("detail-live-activity")
                    }
                    panel {
                        Text("Episodes").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                        EpisodeRows(episodes: episodes, ink: .white, formatter: formatter)
                    }
                    Button("Report a wrong time") {}
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Tokens.Space.m).padding(.vertical, Tokens.Space.s)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .accessibilityIdentifier("detail-report")
                }
                .padding(.horizontal, Tokens.Space.m)
                .padding(.bottom, Tokens.Space.xl)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(scrollAnchor)
            .background { backdrop }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .environment(\.colorScheme, .dark)
    }

    private var backdrop: some View {
        ArtworkLoaderView(url: artwork?.hero, maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
            ArtworkFill(image: hero?.image, palette: hero?.palette ?? .neutral)
                .overlay(LinearGradient(stops: [
                    .init(color: .black.opacity(0.35), location: 0),
                    .init(color: .black.opacity(0.1), location: 0.3),
                    .init(color: .black.opacity(0.55), location: 1),
                ], startPoint: .top, endPoint: .bottom))
        }
        .background(.black)
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            GlassCircleButton(systemImage: "chevron.left", label: "Back") { dismiss() }
            Spacer()
            GlassCircleButton(systemImage: "square.and.arrow.up", label: "Share") {}
        }
    }

    private func centre(now: Date) -> some View {
        VStack(spacing: Tokens.Space.xs) {
            Text(drop.showName)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("detail-title")
            Text(DirectionCopy.episodeAndProvider(drop))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .accessibilityIdentifier("detail-network")
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                          size: 92, tint: .white, formatter: formatter)
                .environment(\.numeralStudy, .glass)
            Text("\(DirectionCopy.yourTime(drop, now: now, formatter: formatter)) your time")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, Tokens.Space.m).padding(.vertical, Tokens.Space.xs)
                .glassEffect(.regular, in: .capsule)
        }
        .shadow(color: .black.opacity(0.4), radius: 8, y: 1)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail-next")
    }

    private func panel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(Tokens.Space.m)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}
#endif
