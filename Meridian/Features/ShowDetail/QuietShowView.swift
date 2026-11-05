import SwiftUI

/// A followed show with nothing scheduled (UX audit #12): its art, its name, why there's no time, its last episodes
/// and Unfollow, so it can be left from Upcoming like any other show. Laid out like Show detail without the next drop;
/// there's no time to report.
struct QuietShowView: View {
    let show: QuietShow
    let artwork: ShowArtwork?
    var episodes: [PastEpisode] = []
    var formatter = DropFormatter()
    var onUnfollow: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    private static let artHeight: CGFloat = 500
    /// Nil artwork is still loading, so the header keeps its height; artwork with no picture gets the short header.
    private var hasArt: Bool { artwork.map { $0.hero != nil } ?? true }

    var body: some View {
        ArtworkLoaderView(url: artwork?.hero, maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
            let base = (hero?.palette ?? .neutral).night.color
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    NightArtHeader(image: hero?.image, base: base, height: Self.artHeight, hasArt: hasArt)
                    VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                            ShowTitle(name: show.name, testID: "quiet-title")
                            Text("Nothing scheduled")
                                .font(.body.weight(.medium))
                                .foregroundStyle(NightInk.primary)
                            Text(ReleaseWording.quietNote(status: show.status, lastAired: show.lastAired,
                                                          formatter: formatter, now: .now))
                                .font(.subheadline)
                                .foregroundStyle(NightInk.secondary)
                                .accessibilityIdentifier("quiet-note")
                        }
                        if !episodes.isEmpty {
                            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                                Text("Episodes")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(NightInk.muted)
                                    .accessibilityAddTraits(.isHeader)
                                EpisodeRows(episodes: episodes, ink: .white, formatter: formatter)
                            }
                        }
                        ShowActionsCard(showName: show.name, onReport: nil) { onUnfollow(); dismiss() }
                    }
                    .padding(.horizontal, Tokens.Space.l)
                    .padding(.top, -64)
                }
                .padding(.bottom, Tokens.Space.xl)
            }
            .scrollIndicators(.hidden)
            .background(base)
            // Once the text passes the art, the status bar gets the page colour behind it (AD-4).
            .statusBarShade(base, art: hasArt ? Self.artHeight : NightArtHeader.noArtHeight)
        }
        // The system bar, invisible, so the edge swipe goes back (as on Show detail).
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .scrollEdgeEffectHidden(true, for: .top)
        .environment(\.colorScheme, .dark)
    }
}
