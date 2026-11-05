import SwiftUI
import UIKit

/// Show detail (SPEC §1, UI-BRIEF §5.4) in Night Sky: the show's art fades into night, then the same three lines as
/// Upcoming, one sentence on where the time came from (D-40), the Live Activity switch, recent episodes, "Report a
/// wrong time" and unfollow. One back button; nothing else sits on the art.
struct ShowDetailView: View {
    let drop: Drop
    let artwork: ShowArtwork?
    var episodes: [PastEpisode] = []
    @Binding var liveActivity: Bool
    /// An anime's stream delay after its Japanese TV time (`detail-offset`); nil hides it for other shows.
    var offset: Binding<Int>? = nil
    /// What the Live Activity switch will really do (UX audit #11); the usual lead line by default.
    var activityStatus: LiveActivityStatus.Line = .starts
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil
    /// "Report a wrong time" (D6-3): `ShowDetailScreen` opens the prefilled report. Nil hides the row (the previews).
    var onReport: (() -> Void)? = nil
    var onUnfollow: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @AppStorage(LeadTime.storageKey) private var leadMinutes = LeadTime.defaultMinutes

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
                        // Only the countdown follows the clock, so only it redraws every second.
                        TimelineView(.countdown) { context in next(now: context.date) }
                        liveActivityRow
                        if let offset { offsetRow(offset) }
                        if !episodes.isEmpty {
                            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                                Text("Episodes")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(NightInk.muted)
                                    .accessibilityAddTraits(.isHeader)
                                EpisodeRows(episodes: episodes, ink: .white, formatter: formatter)
                            }
                        }
                        ShowActionsCard(showName: drop.showName, onReport: onReport) { onUnfollow(); dismiss() }
                    }
                    .padding(.horizontal, Tokens.Space.l)
                    .padding(.top, -64)
                }
                .padding(.bottom, Tokens.Space.xl)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(scrollAnchor)
            .background(base)
            // Once the text passes the art, the status bar gets the page colour behind it (AD-4).
            .statusBarShade(base, art: hasArt ? Self.artHeight : NightArtHeader.noArtHeight)
        }
        // The system bar stays, invisible, so its back button brings the edge swipe back (Chime, 2 Nov: hiding it
        // and drawing our own button switched the gesture off). On iOS 26 that button is a glass circle over the art.
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .scrollEdgeEffectHidden(true, for: .top)
        .environment(\.colorScheme, .dark)
    }

    private func next(now: Date) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            ReleaseHeadline(drop: drop, now: now, formatter: formatter, testID: "detail")
            ReleaseMeta(drop: drop, formatter: formatter)
            // Where the time came from, as one plain sentence instead of a code to learn (D-40).
            Text(ReleaseWording.explanation(drop, broadcastZone: drop.broadcastZone, formatter: formatter))
                .font(.subheadline)
                .foregroundStyle(NightInk.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Tokens.Space.xs)
                .accessibilityIdentifier("detail-why")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail-next")
    }

    /// The switch and one honest line on what it will do (UX audit #11), with a way to iOS Settings when Live
    /// Activities are off there. A grey track at 45% white: the thumb stands out at 4.8:1, where 60% gave 2.5:1 (#20).
    private var liveActivityRow: some View {
        // The link sits beside the switch, not in its label: a Toggle merges its label into one VoiceOver element,
        // which would leave the link unreachable.
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            // Animated, so the status line under it changes with the switch instead of snapping (AD-8).
            Toggle(isOn: $liveActivity.animation(.snappy(duration: 0.25))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Release-night Live Activity").font(.body)
                    Text(LiveActivityStatus.text(activityStatus, leadMinutes: leadMinutes))
                        .font(.footnote).foregroundStyle(NightInk.muted)
                        .accessibilityIdentifier("detail-live-activity-status")
                }
            }
            .tint(Color(white: 0.45))
            .accessibilityIdentifier("detail-live-activity")
            if activityStatus == .systemOff, let settings = URL(string: UIApplication.openSettingsURLString) {
                Link("Open Settings", destination: settings)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    /// An anime streams a set time after its Japanese broadcast: the delay in steps of 15 minutes, said in words.
    /// Changing it refreshes the times, so the countdown, its "Expected" and the Live Activity follow (UX audit #5).
    private func offsetRow(_ minutes: Binding<Int>) -> some View {
        // Animated, or the phrase's `.numericText` roll never plays (AD-8).
        Stepper(value: minutes.animation(.snappy(duration: 0.25)), in: AnimeOffset.range, step: AnimeOffset.step) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stream delay").font(.body)
                Text(AnimeOffset.phrase(minutes.wrappedValue))
                    .font(.footnote).foregroundStyle(NightInk.muted)
                    .contentTransition(.numericText())
            }
        }
        .accessibilityIdentifier("detail-offset")
    }
}

/// One aired episode for Show detail's list.
struct PastEpisode: Hashable, Identifiable, Sendable {
    var id: String { label }
    let label: String
    let title: String
    let airdate: String
}

/// Past episodes, newest first.
struct EpisodeRows: View {
    let episodes: [PastEpisode]
    let ink: Color
    var formatter = DropFormatter()

    /// The episode label's column grows with the text, so "S3E9" never stacks a letter a line (UX audit #7).
    @ScaledMetric(relativeTo: .footnote) private var labelWidth: CGFloat = 52
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(episodes.enumerated()), id: \.element) { index, episode in
                // At the accessibility sizes the label, title and date stack instead of sharing one line.
                let stacked = dynamicTypeSize.isAccessibilitySize
                let line = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: Tokens.Space.xxs))
                    : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Tokens.Space.s))
                line {
                    Text(episode.label)
                        .font(.footnote.monospacedDigit().weight(.semibold))
                        .foregroundStyle(ink.opacity(0.6))
                        .frame(width: stacked ? nil : labelWidth, alignment: .leading)
                    Text(episode.title).font(.body.weight(.medium))
                    if !stacked { Spacer() }
                    Text(formatter.airdate(episode.airdate, now: .now) ?? "").font(.footnote).foregroundStyle(ink.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Tokens.Space.s)
                .overlay(alignment: .bottom) {
                    if index < episodes.count - 1 { Rectangle().fill(ink.opacity(0.12)).frame(height: 1) }
                }
                .accessibilityIdentifier("detail-episode-\(index + 1)")
            }
        }
        .foregroundStyle(ink)
    }
}
