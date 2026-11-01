import SwiftUI
import UIKit

/// The Lock Screen banner (UI-BRIEF §6.2, at most 160 pt tall), on the night base with the show's key art on the
/// right edge fading into it (#Duolingo). On the left, top to bottom: the show's name in serif ("+ 1 more" when
/// same-night drops merge) over "S2E5 · Apple TV · US"; the plain-words label ("Expected in", flipping to "Out now" at
/// the drop, D-49); the serif countdown; then the absolute local time, with the old one struck through after a delay
/// (#43 Qantas). Certainty is said in words only (D-40).
///
/// The view takes `isStale`, `now` and the art rather than reading the activity context or the App Group, so tests
/// render every state.
struct LiveActivityLockScreenView: View {
    let attributes: DropActivityAttributes
    let state: DropActivityAttributes.ContentState
    var art: UIImage?
    var isStale = false
    var now = Date.now
    var formatter = DropFormatter()

    /// The room the words leave on the right for the art's clear part (or the faint initial).
    static let artReserve: CGFloat = 112

    @Environment(\.isLuminanceReduced) private var dimmed

    private var out: Bool { LiveActivityText.isOut(state, isStale: isStale, now: now) }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                title
                let details = LiveActivityText.details(attributes)
                if !details.isEmpty {
                    Text(details)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ink(LiveActivityInk.muted))
                        .lineLimit(1)
                        .padding(.top, 2)
                        .accessibilityIdentifier("la-details")
                }
                Text(LiveActivityText.band(attributes, out: out))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(out ? LiveActivityInk.primary : ink(LiveActivityInk.secondary))
                    .lineLimit(1)
                    .padding(.top, 12)
                    .accessibilityIdentifier("la-label")
                LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 36)
                    .accessibilityIdentifier("la-countdown")
                timeLine
                    .padding(.top, 2)
            }
            Spacer(minLength: Self.artReserve)
        }
        .padding(.horizontal, Tokens.Space.m)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { LiveActivityArtEdge(attributes: attributes, art: art) }
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LiveActivityText.accessibilityLabel(attributes, state: state, isStale: isStale, now: now,
                                                                formatter: formatter))
    }

    /// "Silo" in serif, then "+ 1 more" smaller when same-night drops merge. A long name truncates; "+ 1 more" stays.
    private var title: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: attributes.showName.trimmingCharacters(in: .whitespaces))
                .font(.system(size: 19, weight: .medium, design: .serif))
                .foregroundStyle(ink(LiveActivityInk.primary))
                .lineLimit(1)
                .truncationMode(.tail)
                .accessibilityIdentifier("la-title")
            if let more = LiveActivityText.more(attributes) {
                Text(more)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ink(LiveActivityInk.secondary))
                    .fixedSize()
                    .accessibilityIdentifier("la-more")
            }
        }
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
