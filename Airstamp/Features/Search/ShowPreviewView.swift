import SwiftData
import SwiftUI

/// The page any poster on the Search tab opens (Chime, 1 Nov 2026), in Night Sky like Upcoming and Show detail: the
/// show's key art fading into night with one back button on it, then the title, the giant serif countdown and when
/// it's out in the app's words, the year · network · status line, and Follow. With nothing scheduled there's no
/// countdown or release line, just the title. The poster's (+) still follows in one tap without opening this page.
struct ShowPreviewView: View {
    let route: ShowRoute
    let client: TVmazeClient
    let anilist: AniListClient
    let rules: RulesFile

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var followed: [FollowedShow]
    @State private var drop: Drop?
    @State private var artwork: ShowArtwork?
    @State private var loaded = false

    private var result: SearchResult { route.result }
    private var followedShow: FollowedShow? {
        followed.first { $0.key == FollowedShow.key(catalog: result.catalog, id: result.id) }
    }
    private var following: Bool { followedShow != nil }
    /// The key art once known; the poster if the show has none. Nothing until then, so the poster never flashes in
    /// before the key art replaces it.
    private var heroURL: URL? { loaded ? artwork?.hero ?? result.largePoster : nil }

    var body: some View {
        // Every second, so the countdown ticks (a TimelineView paces its ticking Text; see UpcomingView).
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            ArtworkLoaderView(url: heroURL, maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
                let base = (hero?.palette ?? .neutral).night.color
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        NightArtHeader(image: hero?.image, base: base, height: 500)
                            .accessibilityElement()
                            .accessibilityLabel("\(result.title) artwork")
                            .accessibilityAddTraits(.isImage)
                            .accessibilityIdentifier("show-preview-art")
                            .overlay(alignment: .topLeading) {
                                GlassCircleButton(systemImage: "chevron.left", label: "Back") { dismiss() }
                                    .padding(.leading, Tokens.Space.m)
                                    .padding(.top, 58)
                            }
                        VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                                if let drop {
                                    ReleaseHeadline(drop: drop, now: timeline.date, testID: "show-preview")
                                } else {
                                    Text(result.title)
                                        .font(.system(size: 32, design: .serif))
                                        .lineLimit(2).minimumScaleFactor(0.7)
                                        .accessibilityAddTraits(.isHeader)
                                        .accessibilityIdentifier("show-preview-title")
                                }
                                if !result.meta.isEmpty {
                                    Text(result.meta)
                                        .font(.footnote)
                                        .foregroundStyle(NightInk.muted)
                                        .accessibilityIdentifier("show-preview-meta")
                                }
                            }
                            followButton
                        }
                        .padding(.horizontal, Tokens.Space.l)
                        .padding(.top, -64)
                    }
                    .padding(.bottom, Tokens.Space.xl)
                }
                .scrollIndicators(.hidden)
                .background(base)
                .ignoresSafeArea(edges: .top)
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .environment(\.colorScheme, .dark)
        .task {
            guard !loaded else { return }
            // A followed show's own adjustment moves its time, as on Upcoming; the grid's drop doesn't carry it.
            let offset = followedShow?.animeOffsetMinutes ?? 0
            let fetched = await ShowPreview.load(catalog: result.catalog, id: result.id,
                                                 knownDrop: offset == 0 ? route.knownDrop : nil, client: client,
                                                 anilist: anilist, rules: rules, offsetMinutes: offset)
            // Leaving the page (or the tab) mid-request cancels it; ask again on return instead of keeping nothing.
            guard !Task.isCancelled else { return }
            drop = fetched.drop
            artwork = fetched.artwork
            loaded = true
        }
    }

    /// White "Follow" until followed, then a dark "Following" with a check, like the poster's (+).
    private var followButton: some View {
        Button {
            let store = FollowStore(context: context)
            try? following ? store.unfollow(catalog: result.catalog, id: result.id) : store.follow(result.followShow)
        } label: {
            Label(following ? "Following" : "Follow", systemImage: following ? "checkmark" : "plus")
                .font(.headline)
                .foregroundStyle(following ? .white : .black)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(following ? AnyShapeStyle(.white.opacity(0.12)) : AnyShapeStyle(.white), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(following ? 0.35 : 0)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(following ? "Following \(result.title)" : "Follow \(result.title)")
        .accessibilityIdentifier("show-preview-follow")
    }
}
