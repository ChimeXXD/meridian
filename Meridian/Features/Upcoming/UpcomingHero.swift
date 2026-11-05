import SwiftUI

/// The next drop at the top of Upcoming: its art fading into night, then the title, a giant light serif countdown,
/// when it's out (worded by certainty, D-40), and the episode and provider on one quiet line.
struct UpcomingHero: View {
    let drop: Drop
    let image: UIImage?
    let base: Color
    /// False once the show is known to have no art: the short header (EA-13).
    var hasArt = true
    var formatter = DropFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NightArtHeader(image: image, base: base, hasArt: hasArt)
            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                // Only the headline follows the clock, so only it redraws every second, not the art above it.
                TimelineView(.countdown) { context in
                    ReleaseHeadline(drop: drop, now: context.date, formatter: formatter, testID: "upcoming-hero")
                }
                ReleaseMeta(drop: drop, formatter: formatter)
            }
            .padding(.horizontal, Tokens.Space.l)
            .padding(.top, -64)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("upcoming-hero")
    }
}

/// Title, countdown, and when it's out: the three lines that answer the question.
struct ReleaseHeadline: View {
    let drop: Drop
    let now: Date
    var formatter = DropFormatter()
    var titleSize: CGFloat = 32
    /// 64 on Upcoming and Show detail, 48 on the show page: 2 and 1.5 times the title. It was 88, 2.75 times, and
    /// took 15% of the screen (Chime and the UX audit, 2 Nov).
    var countdownSize: CGFloat = 64
    /// Prefix for the test IDs: `upcoming-hero` or `detail` (UI-BRIEF).
    var testID = "headline"
    /// False when the page draws the title itself, above lines that load later (the show page, EA-9).
    var showsTitle = true

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            if showsTitle {
                ShowTitle(name: drop.showName, size: titleSize, testID: "\(testID)-title")
            }
            // A date-only drop has no countdown: its day is in the out line, so it isn't said twice in big type.
            if drop.confidence != .dateOnly {
                // The slot holds the line's height at the drop and brings "Out now" in (EA-2).
                CountdownSlot(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                              size: countdownSize, formatter: formatter)
                    .environment(\.numeralStudy, .night)
                    // The light serif's digits carry a side bearing, so at the same x they start 2 pt right of the
                    // title's first letter; pulled back by 3% of the size to line up optically (EA-16).
                    .padding(.leading, -countdownSize * 0.03)
            }
            Text(ReleaseWording.outLine(drop, now: now, formatter: formatter, naming: true))
                .font(.body.weight(.medium))
                .foregroundStyle(NightInk.primary)
                .padding(.top, Tokens.Space.xxs)
                .accessibilityIdentifier("\(testID)-out")
        }
    }
}

/// A page's show title in New York, growing like a large title so it never ends up smaller than the lines under it.
struct ShowTitle: View {
    let name: String
    var size: CGFloat = 32
    let testID: String

    var body: some View {
        Text(name)
            .serif(size, relativeTo: .largeTitle)
            .showTitleLines()
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(testID)
    }
}

/// "Delayed from 21:00" when a sure time moved later (D-58), "S4E1 · Apple TV" in muted text, and "No official
/// stream in your country" when the rules file says so.
struct ReleaseMeta: View {
    let drop: Drop
    /// The screen's formatter, so a delay's old time follows the Settings zone like the out line above it.
    let formatter: DropFormatter

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let delay = ReleaseWording.delayLine(drop, formatter: formatter) {
                Text(delay)
                    .font(.footnote)
                    .foregroundStyle(NightInk.muted)
                    .accessibilityIdentifier("release-delayed")
            }
            // One line normally; never cut at the accessibility sizes, where "HBO · US" lost its country (audit #6).
            Text(ProviderLabel.wrapping(drop.episodeAndProvider))
                .accessibilityLabel(drop.spokenEpisodeAndProvider)
                .font(.footnote)
                .foregroundStyle(NightInk.muted)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            if drop.provider?.noOfficialStream == true {
                Text("No official stream in your country")
                    .font(.footnote)
                    .foregroundStyle(NightInk.muted)
                    .accessibilityIdentifier("provider-no-stream")
            }
        }
    }
}
