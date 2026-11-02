import SwiftUI

/// The next drop at the top of Upcoming: its art fading into night, then the title, a giant light serif countdown,
/// when it's out (worded by certainty, D-40), and the episode and provider on one quiet line.
struct UpcomingHero: View {
    let drop: Drop
    let image: UIImage?
    let base: Color
    let now: Date
    var formatter = DropFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NightArtHeader(image: image, base: base)
            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                ReleaseHeadline(drop: drop, now: now, formatter: formatter, testID: "upcoming-hero")
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
    var countdownSize: CGFloat = 88
    /// Prefix for the test IDs: `upcoming-hero` or `detail` (UI-BRIEF).
    var testID = "headline"

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Text(drop.showName)
                .font(.system(size: titleSize, design: .serif))
                .lineLimit(2).minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("\(testID)-title")
            CountdownText(drop: drop.date, confidence: drop.confidence, airdate: drop.airdate, now: now,
                          size: countdownSize, tint: .white, formatter: formatter)
                .environment(\.numeralStudy, .night)
            Text(ReleaseWording.outLine(drop, now: now, formatter: formatter, naming: true))
                .font(.body.weight(.medium))
                .foregroundStyle(NightInk.primary)
                .padding(.top, Tokens.Space.xxs)
                .accessibilityIdentifier("\(testID)-out")
        }
    }
}

/// "Delayed from 21:00" when a sure time moved later (D-58), "S4E1 · Apple TV" in muted text, and "No official
/// stream in your country" when the rules file says so.
struct ReleaseMeta: View {
    let drop: Drop
    /// The screen's formatter, so a delay's old time follows the Settings zone like the out line above it.
    let formatter: DropFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let delay = ReleaseWording.delayLine(drop, formatter: formatter) {
                Text(delay)
                    .font(.footnote)
                    .foregroundStyle(NightInk.muted)
                    .accessibilityIdentifier("release-delayed")
            }
            Text(drop.episodeAndProvider)
                .font(.footnote)
                .foregroundStyle(NightInk.muted)
                .lineLimit(1)
            if drop.provider?.noOfficialStream == true {
                Text("No official stream in your country")
                    .font(.footnote)
                    .foregroundStyle(NightInk.muted)
                    .accessibilityIdentifier("provider-no-stream")
            }
        }
    }
}
