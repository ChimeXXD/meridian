import SwiftUI

/// Show detail (SPEC §1, UI-BRIEF §5.4) in Night Sky: the show's art fades into night, then the same three lines as
/// Upcoming, one sentence on where the time came from (D-40), the Live Activity switch, recent episodes, "Report a
/// wrong time" and unfollow. One back button; nothing else sits on the art.
struct ShowDetailView: View {
    let drop: Drop
    let artwork: ShowArtwork?
    var episodes: [PastEpisode] = []
    @Binding var liveActivity: Bool
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil
    /// "Report a wrong time" (D6-3): `ShowDetailScreen` opens the prefilled report. Nil hides the row (the previews).
    var onReport: (() -> Void)? = nil
    var onUnfollow: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var confirmingUnfollow = false
    @AppStorage(LeadTime.storageKey) private var leadMinutes = LeadTime.defaultMinutes

    var body: some View {
        ArtworkLoaderView(url: artwork?.hero, maxPixel: ShowArtwork.idealBackgroundWidth) { hero in
            let base = (hero?.palette ?? .neutral).night.color
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    NightArtHeader(image: hero?.image, base: base, height: 500)
                    VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                        // Only the countdown follows the clock, so only it redraws every second.
                        TimelineView(.countdown) { context in next(now: context.date) }
                        liveActivityRow
                        if !episodes.isEmpty {
                            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                                Text("Episodes")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(NightInk.muted)
                                    .accessibilityAddTraits(.isHeader)
                                EpisodeRows(episodes: episodes, ink: .white, formatter: formatter)
                            }
                        }
                        // Each a 44 pt row, so the tap target is the HIG minimum, not the text's 20.
                        VStack(alignment: .leading, spacing: 0) {
                            if let onReport {
                                Button(action: onReport) { tapRow("Report a wrong time") }
                                    .accessibilityIdentifier("detail-report")
                            }
                            Button(role: .destructive) { confirmingUnfollow = true } label: { tapRow("Unfollow") }
                                .accessibilityIdentifier("detail-unfollow")
                        }
                        .font(.subheadline)
                        .foregroundStyle(NightInk.muted)
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
        // The system bar stays, invisible, so its back button brings the edge swipe back (Chime, 2 Nov: hiding it
        // and drawing our own button switched the gesture off). On iOS 26 that button is a glass circle over the art.
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .scrollEdgeEffectHidden(true, for: .top)
        .environment(\.colorScheme, .dark)
        .confirmationDialog("Stop following \(drop.showName)?", isPresented: $confirmingUnfollow, titleVisibility: .visible) {
            Button("Unfollow", role: .destructive) { onUnfollow(); dismiss() }
        }
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

    private var liveActivityRow: some View {
        Toggle(isOn: $liveActivity) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Release-night Live Activity").font(.body)
                Text("Starts \(LeadTime.phrase(minutes: leadMinutes)) before, on your Lock Screen")
                    .font(.footnote).foregroundStyle(NightInk.muted)
            }
        }
        .tint(.white.opacity(0.6))
        .accessibilityIdentifier("detail-live-activity")
    }

    /// A text button's label, 44 pt tall and tappable across that height.
    private func tapRow(_ title: String) -> some View {
        Text(title)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(.rect)
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

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(episodes.enumerated()), id: \.element) { index, episode in
                HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s) {
                    Text(episode.label)
                        .font(.footnote.monospacedDigit().weight(.semibold))
                        .foregroundStyle(ink.opacity(0.6))
                        .frame(width: 52, alignment: .leading)
                    Text(episode.title).font(.body.weight(.medium))
                    Spacer()
                    Text(formatter.airdate(episode.airdate, now: .now) ?? "").font(.footnote).foregroundStyle(ink.opacity(0.6))
                }
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
