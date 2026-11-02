import SwiftUI

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
    var formatter = DropFormatter()
    var scrollAnchor: UnitPoint? = nil
    /// "Report a wrong time" (D6-3): `ShowDetailScreen` opens the prefilled report. Nil hides the row (the previews).
    var onReport: (() -> Void)? = nil
    var onUnfollow: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    /// The action rows' symbol column grows with the text, so a large symbol never overlaps its label.
    @ScaledMetric(relativeTo: .body) private var iconColumn: CGFloat = 24
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
                        actions
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

    /// An anime streams a set time after its Japanese broadcast: the delay in steps of 15 minutes, said in words.
    /// Changing it refreshes the times, so the countdown, its "Expected" and the Live Activity follow (UX audit #5).
    private func offsetRow(_ minutes: Binding<Int>) -> some View {
        Stepper(value: minutes, in: AnimeOffset.range, step: AnimeOffset.step) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stream delay").font(.body)
                Text(AnimeOffset.phrase(minutes.wrappedValue))
                    .font(.footnote).foregroundStyle(NightInk.muted)
                    .contentTransition(.numericText())
            }
        }
        .accessibilityIdentifier("detail-offset")
    }

    /// Report and Unfollow as a grouped card, like Settings' rows (Chime and the UX audit #4, 2 Nov: as grey text they
    /// looked disabled, and the grey hid Unfollow's red). Report shows it leaves the app; Unfollow is red and still asks.
    private var actions: some View {
        VStack(spacing: 0) {
            if let onReport {
                Button(action: onReport) {
                    actionRow("Report a wrong time", systemImage: "exclamationmark.bubble", ink: .white, leavesApp: true)
                }
                .accessibilityIdentifier("detail-report")
                .accessibilityHint(ReportRoute.current == .githubIssue ? "Opens a GitHub issue" : "Opens an email")
                Rectangle().fill(.white.opacity(0.12)).frame(height: 0.5)
                    .padding(.leading, Tokens.Space.m + iconColumn + Tokens.Space.s)
            }
            Button(role: .destructive) { confirmingUnfollow = true } label: {
                actionRow("Unfollow", systemImage: "minus.circle", ink: Color(uiColor: .systemRed), leavesApp: false)
            }
            .accessibilityIdentifier("detail-unfollow")
        }
        .buttonStyle(.plain)
        .background(.white.opacity(0.08), in: .rect(cornerRadius: Tokens.Radius.card))
    }

    /// One row: a symbol in a fixed column, the label, and an arrow when it opens another app. At least 52 pt tall,
    /// tappable across its width.
    private func actionRow(_ title: String, systemImage: String, ink: Color, leavesApp: Bool) -> some View {
        HStack(spacing: Tokens.Space.s) {
            Image(systemName: systemImage)
                .font(.body)
                .frame(width: iconColumn)
                .accessibilityHidden(true)
            Text(title)
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            if leavesApp {
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(NightInk.muted)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(ink)
        .padding(.horizontal, Tokens.Space.m)
        .frame(minHeight: 52)
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
