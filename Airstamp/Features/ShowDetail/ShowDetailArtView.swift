import SwiftUI

/// Show detail in the artwork-led direction (D-37): key art runs edge to edge and melts into the page, which takes
/// its colour from the art (Apple Music, HBO Max, Plex picks). The next episode leads with a large thin serif
/// countdown (Insight Timer), then your time against the broadcast time, the Live Activity switch and episodes.
struct ShowDetailArtView: View {
    struct PastEpisode: Hashable, Identifiable {
        var id: String { label }
        let label: String
        let title: String
        let airdate: String
    }

    let drop: Drop
    let artwork: ShowArtwork?
    var episodes: [PastEpisode] = []
    /// The network's own zone, for "Broadcast Thu 21:00 EDT". Nil hides the line: only a `.broadcast` time has one,
    /// and the caller must know the network's zone rather than assume New York.
    var broadcastZone: String? = nil
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil

    @State private var liveActivity = true

    var body: some View {
        TimelineView(.everyMinute) { context in
            ArtworkLoaderView(url: artwork?.hero, maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
                let palette = hero?.palette ?? .neutral
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header(image: hero?.image, palette: palette)
                        VStack(alignment: .leading, spacing: Tokens.Space.l) {
                            next(now: context.date)
                            liveActivityRow(palette: palette)
                            episodeList
                            Button("Report a wrong time") {}
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(palette.accent.color)
                                .accessibilityIdentifier("detail-report")
                        }
                        .padding(.horizontal, Tokens.Space.l)
                        .padding(.bottom, Tokens.Space.xl)
                    }
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(scrollAnchor)
                .background(palette.base.color)
                .overlay(alignment: .top) { StatusBarScrim(color: palette.base.color) }
                .ignoresSafeArea(edges: .top)
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private func header(image: UIImage?, palette: ArtworkPalette) -> some View {
        ZStack(alignment: .bottomLeading) {
            ArtworkFill(image: image, palette: palette).frame(height: 470)
            LinearGradient(stops: [
                .init(color: palette.base.color.opacity(0), location: 0.35),
                .init(color: palette.base.color, location: 0.97),
            ], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text(drop.provider?.display.uppercased() ?? "")
                    .font(.caption.weight(.semibold)).tracking(1.6)
                    .foregroundStyle(.white.opacity(0.75))
                    .accessibilityIdentifier("detail-network")
                Text(drop.showName)
                    .font(.system(size: 44, weight: .bold))
                    .lineLimit(2).minimumScaleFactor(0.7)
                    .accessibilityIdentifier("detail-title")
            }
            .padding(.horizontal, Tokens.Space.l)
            .padding(.bottom, Tokens.Space.s)
        }
        .frame(height: 470)
    }

    private func next(now: Date) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("NEXT EPISODE\(drop.episodeLabel.map { " · \($0)" } ?? "")")
                .font(.caption.weight(.semibold)).tracking(1.6)
                .foregroundStyle(.white.opacity(0.7))
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                          size: 80, tint: .white, formatter: formatter)
                .environment(\.numeralStudy, .night)
            // A date-only drop's `date` is just a sort key (D-28): no local time and no broadcast time.
            if drop.confidence == .dateOnly {
                Text("Time not announced")
                    .font(.title3.weight(.semibold))
            } else {
                Text("\(formatter.relativeDay(drop.date, now: now)) \(formatter.localTime(drop.date)) your time")
                    .font(.title3.weight(.semibold))
                if case .broadcast = drop.source, let broadcastZone {
                    let broadcast = DropFormatter(zoneIdentifier: broadcastZone, locale: formatter.locale)
                    Text("Broadcast \(broadcast.weekdayTime(drop.date)) \(broadcast.zoneAbbreviation(drop.date))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .accessibilityIdentifier("detail-broadcast")
                }
            }
            SourceChip(source: drop.source, confidence: drop.confidence)
                .padding(.top, Tokens.Space.xxs)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail-next")
    }

    private func liveActivityRow(palette: ArtworkPalette) -> some View {
        Toggle(isOn: $liveActivity) {
            VStack(alignment: .leading, spacing: 2) {
                Label("Release-night Live Activity", systemImage: "bell.badge").font(.headline)
                Text("Starts 2 hours before, on your Lock Screen").font(.footnote).foregroundStyle(.white.opacity(0.7))
            }
        }
        .tint(palette.accent.color)
        .padding(Tokens.Space.m)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Tokens.Radius.sheet))
        .accessibilityIdentifier("detail-live-activity")
    }

    private var episodeList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Episodes").font(.title3.weight(.bold)).padding(.bottom, Tokens.Space.xs)
            ForEach(Array(episodes.enumerated()), id: \.element) { index, episode in
                HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s) {
                    Text(episode.label)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 52, alignment: .leading)
                    Text(episode.title).font(.body.weight(.medium))
                    Spacer()
                    Text(formatter.airdate(episode.airdate) ?? "").font(.footnote).foregroundStyle(.white.opacity(0.6))
                }
                .padding(.vertical, Tokens.Space.s)
                .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.1)).frame(height: 1) }
                .accessibilityIdentifier("detail-episode-\(index + 1)")
            }
        }
    }
}
