import SwiftUI

/// The Lock Screen banner (UI-BRIEF §6.2, at most 160 pt tall). Top to bottom: the breadcrumb, the show's name in
/// serif and the rest muted (#128 Apple Sports), with "+ 1 more" on the right when same-night drops merge; the header
/// band that carries the certainty ("Expected in") and flips to "Out now" at the drop (#146 Strava); the big light
/// serif countdown (#135 Waymo); then the absolute local time, relative first and absolute second (#130 Transit). A
/// moved time keeps the old one struck through beside it (#43 Qantas). Certainty is said in words only (D-40).
///
/// The view takes `isStale` and `now` rather than reading the activity context, so tests render every state.
struct LiveActivityLockScreenView: View {
    let attributes: DropActivityAttributes
    let state: DropActivityAttributes.ContentState
    var isStale = false
    var now = Date.now
    var formatter = DropFormatter()

    @Environment(\.isLuminanceReduced) private var dimmed

    private var out: Bool { LiveActivityText.isOut(state, isStale: isStale, now: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.xs) {
                breadcrumb
                Spacer(minLength: 0)
                if let more = LiveActivityText.more(attributes) {
                    Text(more)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ink(LiveActivityInk.primary))
                        .fixedSize()
                        .accessibilityIdentifier("la-more")
                }
            }
            band
                .padding(.top, 10)
            LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 44)
                .padding(.top, 2)
                .accessibilityIdentifier("la-countdown")
            timeLine
        }
        .padding(.horizontal, Tokens.Space.m)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LiveActivityText.accessibilityLabel(attributes, state: state, isStale: isStale, now: now,
                                                                formatter: formatter))
    }

    /// "Silo · S2E5 · Apple TV · US", the name in serif.
    private var breadcrumb: some View {
        let crumb = LiveActivityText.breadcrumb(attributes)
        // Trimmed as `breadcrumb` trims it, so a stray space can't push the whole name into the muted tail.
        let name = attributes.showName.trimmingCharacters(in: .whitespaces)
        let rest = crumb.hasPrefix(name) ? String(crumb.dropFirst(name.count)) : crumb
        let title = Text(verbatim: crumb.hasPrefix(name) ? name : "")
            .font(.system(size: 15, weight: .medium, design: .serif))
            .foregroundStyle(ink(LiveActivityInk.primary))
        let tail = Text(verbatim: rest)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(ink(LiveActivityInk.muted))
        return Text("\(title)\(tail)")
            .lineLimit(1)
            .truncationMode(.tail)
            .accessibilityIdentifier("la-breadcrumb")
    }

    private var band: some View {
        Text(LiveActivityText.band(attributes, out: out))
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(out ? LiveActivityInk.bandOutText : ink(LiveActivityInk.secondary))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, Tokens.Space.xxs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(out ? LiveActivityInk.bandOut : LiveActivityInk.band,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityIdentifier("la-band")
    }

    /// "Expected Fri 02:00", with the old time struck through after a delay.
    private var timeLine: some View {
        HStack(spacing: 6) {
            Text(LiveActivityText.timeLine(attributes, dropDate: state.dropDate, formatter: formatter))
                .foregroundStyle(ink(LiveActivityInk.secondary))
            if let previous = LiveActivityText.previousTime(state, formatter: formatter) {
                Text(previous)
                    .strikethrough()
                    .foregroundStyle(ink(LiveActivityInk.muted))
                    .accessibilityIdentifier("la-previous")
            }
        }
        .font(.system(size: 13, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityIdentifier("la-time")
    }

    /// Always-On lowers everything but the countdown a little further, as on the widgets.
    private func ink(_ color: Color) -> Color {
        WidgetInk.dimmed(color, when: dimmed)
    }
}
