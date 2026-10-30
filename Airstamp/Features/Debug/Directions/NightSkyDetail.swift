#if DEBUG
import SwiftUI

/// Night Sky Show detail (D-38): the show's art fades into night, then the same three lines as Upcoming (title,
/// countdown, when it's out), your time against the broadcast time, the Live Activity switch and past episodes.
/// One back button; nothing sits on the art.
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
                    VStack(alignment: .leading, spacing: 0) {
                        header(image: hero?.image, base: base)
                        VStack(alignment: .leading, spacing: 36) {
                            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                                NightSkyHeadline(drop: drop, now: context.date, formatter: formatter,
                                                 titleSize: 38, countdownSize: 92, testID: "detail")
                                NightSkyMeta(drop: drop)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("detail-next")
                            FactRows(rows: DirectionCopy.timeFacts(drop, now: context.date, zone: broadcastZone,
                                                                   formatter: formatter),
                                     ink: .white, serif: true)
                            liveActivityRow
                            if !episodes.isEmpty {
                                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                                    Text("EPISODES")
                                        .font(.caption.weight(.semibold)).tracking(1.4)
                                        .foregroundStyle(.white.opacity(0.5))
                                        .accessibilityAddTraits(.isHeader)
                                    EpisodeRows(episodes: episodes, ink: .white, serif: true, formatter: formatter)
                                }
                            }
                            Button("Report a wrong time") {}
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                                .accessibilityIdentifier("detail-report")
                        }
                        .padding(.horizontal, Tokens.Space.l)
                        .padding(.top, -64)
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
        ZStack(alignment: .topLeading) {
            ArtworkFill(image: image, palette: .neutral).frame(height: 500)
            LinearGradient(stops: [.init(color: base.opacity(0), location: 0.4), .init(color: base, location: 1)],
                           startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.25))
            GlassCircleButton(systemImage: "chevron.left", label: "Back") { dismiss() }
                .padding(.leading, Tokens.Space.m)
                .padding(.top, 58)
        }
        .frame(height: 500)
    }

    private var liveActivityRow: some View {
        Toggle(isOn: $liveActivity) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Release-night Live Activity").font(.system(size: 18, design: .serif))
                Text("Starts 2 hours before, on your Lock Screen").font(.footnote).foregroundStyle(.white.opacity(0.6))
            }
        }
        .tint(.white.opacity(0.6))
        .accessibilityIdentifier("detail-live-activity")
    }
}
#endif
