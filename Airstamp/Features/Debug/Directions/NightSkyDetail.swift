#if DEBUG
import SwiftUI

/// Direction A, Show detail: Insight Timer's player screen nearly as it is. The art fills the top with a round glass
/// button on it (here the Live Activity bell), the countdown and bar sit on the night base, then the facts and
/// episodes continue in the same quiet serif style.
struct NightSkyDetail: View {
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
            ArtworkLoaderView(url: artwork?.hero, maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
                let base = (hero?.palette ?? .neutral).night.color
                ScrollView {
                    VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                        header(image: hero?.image, base: base)
                        VStack(alignment: .leading, spacing: Tokens.Space.l) {
                            Text(drop.showName)
                                .font(.system(size: 40, design: .serif))
                                .lineLimit(2).minimumScaleFactor(0.7)
                                .accessibilityIdentifier("detail-title")
                            NightSkyPlayer(drop: drop, now: context.date, formatter: formatter, countdownSize: 92, showTitle: false,
                                           showControls: false)
                            FactRows(rows: DirectionCopy.facts(drop, now: context.date, zone: broadcastZone, formatter: formatter), ink: .white, serif: true)
                            liveActivityRow
                            if !episodes.isEmpty {
                                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                                    Text("Episodes").font(.system(size: 26, design: .serif)).accessibilityAddTraits(.isHeader)
                                    EpisodeRows(episodes: episodes, ink: .white, serif: true, formatter: formatter)
                                }
                            }
                            Button("Report a wrong time") {}
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.75))
                                .accessibilityIdentifier("detail-report")
                        }
                        .padding(.horizontal, Tokens.Space.l)
                        .padding(.top, -60)
                    }
                    .padding(.bottom, Tokens.Space.xl)
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(scrollAnchor)
                .background(base)
                .ignoresSafeArea(edges: .top)
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .environment(\.colorScheme, .dark)
    }

    private func header(image: UIImage?, base: Color) -> some View {
        ZStack {
            ArtworkFill(image: image, palette: .neutral).frame(height: 500)
            LinearGradient(stops: [.init(color: base.opacity(0), location: 0.45), .init(color: base, location: 1)],
                           startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.25))
            VStack {
                HStack {
                    GlassCircleButton(systemImage: "chevron.left", label: "Back") { dismiss() }
                    Spacer()
                    GlassCircleButton(systemImage: "square.and.arrow.up", label: "Share") {}
                }
                .padding(.horizontal, Tokens.Space.m)
                .padding(.top, 58)
                Spacer()
                // Insight Timer's glass pause button, as the Live Activity switch.
                GlassCircleButton(systemImage: liveActivity ? "bell.fill" : "bell.slash", label: "Release-night Live Activity",
                                  size: 84) { liveActivity.toggle() }
                    .padding(.bottom, 110)
                    .accessibilityValue(liveActivity ? "On" : "Off")
                    .accessibilityIdentifier("detail-live-activity-button")
            }
        }
        .frame(height: 500)
    }

    private var liveActivityRow: some View {
        Toggle(isOn: $liveActivity) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Release-night Live Activity").font(.system(size: 18, design: .serif))
                Text("Starts 2 hours before, on your Lock Screen").font(.footnote).foregroundStyle(.white.opacity(0.65))
            }
        }
        .tint(.white.opacity(0.6))
        .accessibilityIdentifier("detail-live-activity")
    }
}
#endif
