import SwiftData
import SwiftUI

/// The page any poster on the Search tab opens (Chime, 1 Nov 2026): the poster, the title with year · network ·
/// country, the next release in the app's words ("Expected Fri 7 Nov at 02:00"), and Follow. With nothing scheduled
/// the release line is left out entirely. The poster's (+) still follows in one tap without opening this page.
struct ShowPreviewView: View {
    let route: ShowRoute
    let client: TVmazeClient
    let anilist: AniListClient
    let rules: RulesFile

    @Environment(\.modelContext) private var context
    @Query private var followed: [FollowedShow]
    @State private var drop: Drop?
    @State private var loaded = false

    private static let page = ArtworkPalette.neutral.night.color
    private var result: SearchResult { route.result }
    private var followedShow: FollowedShow? {
        followed.first { $0.key == FollowedShow.key(catalog: result.catalog, id: result.id) }
    }
    private var following: Bool { followedShow != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.m) {
                PosterImage(url: result.largePoster, cornerRadius: 12)
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .frame(maxWidth: 240)
                    .frame(maxWidth: .infinity)
                    .accessibilityElement()
                    .accessibilityLabel("\(result.title) poster")
                    .accessibilityAddTraits(.isImage)
                    .accessibilityIdentifier("show-preview-poster")
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text(result.title)
                        .font(.system(size: 30, design: .serif))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("show-preview-title")
                    if !result.meta.isEmpty {
                        Text(result.meta)
                            .foregroundStyle(NightInk.muted)
                            .accessibilityIdentifier("show-preview-meta")
                    }
                }
                if let drop {
                    TimelineView(.everyMinute) { context in
                        Text(ReleaseWording.outLine(drop, now: context.date, formatter: DropFormatter()))
                            .font(.title3.weight(.medium))
                    }
                    .accessibilityIdentifier("show-preview-release")
                }
                followButton
            }
            .padding(.horizontal, Tokens.Space.m)
            .padding(.vertical, Tokens.Space.l)
        }
        .scrollIndicators(.hidden)
        .background(Self.page)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .task {
            guard !loaded else { return }
            // A followed show's own adjustment moves its time, as on Upcoming; the grid's drop doesn't carry it.
            let offset = followedShow?.animeOffsetMinutes ?? 0
            if offset == 0, let known = route.knownDrop {
                drop = known
            } else {
                let fetched = await ShowPreview.nextDrop(catalog: result.catalog, id: result.id, client: client,
                                                         anilist: anilist, rules: rules, offsetMinutes: offset)
                // Leaving the page (or the tab) mid-request cancels it; ask again on return instead of keeping nothing.
                guard !Task.isCancelled else { return }
                drop = fetched
            }
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
