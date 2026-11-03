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

    @State private var confirmingUnfollow = false
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
        ArtworkLoaderView(url: heroURL, maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
            let base = (hero?.palette ?? .neutral).night.color
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    NightArtHeader(image: hero?.image, base: base, height: 500)
                        .accessibilityElement()
                        .accessibilityLabel("\(result.title) artwork")
                        .accessibilityAddTraits(.isImage)
                        .accessibilityIdentifier("show-preview-art")
                    VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                        VStack(alignment: .leading, spacing: Tokens.Space.s) {
                            if let drop {
                                // Only the countdown follows the clock, so only it redraws every second.
                                TimelineView(.countdown) { timeline in
                                    ReleaseHeadline(drop: drop, now: timeline.date, countdownSize: 48,
                                                    testID: "show-preview")
                                }
                            } else {
                                Text(result.title)
                                    .serif(32, relativeTo: .largeTitle)
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
        // The system bar stays, invisible, so its back button brings the edge swipe back (Chime, 2 Nov: hiding it
        // and drawing our own button switched the gesture off). On iOS 26 that button is a glass circle over the art.
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .scrollEdgeEffectHidden(true, for: .top)
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
        // Following is one tap; unfollowing asks first, as everywhere (UX audit #15).
        Button {
            if following { confirmingUnfollow = true } else { try? FollowStore(context: context).follow(result.followShow) }
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
        .sensoryFeedback(.success, trigger: following) { old, new in !old && new }
        .accessibilityIdentifier("show-preview-follow")
        .unfollowConfirmation(result.title, isPresented: $confirmingUnfollow) {
            try? FollowStore(context: context).unfollow(catalog: result.catalog, id: result.id)
        }
    }
}
