import SwiftUI
import UIKit

/// The Lock Screen banner (UI-BRIEF §6.2, at most 160 pt tall), on the night base with the show's key art on the
/// right edge fading into it (#Duolingo). On the left, top to bottom: the show's name in serif on up to two lines
/// ("+ 1 more" when same-night drops merge) over "S2E5 · Apple TV · US", which keeps its country when it shortens;
/// the serif countdown, which "Out now" in gold replaces at the
/// drop (D-49), as in the island and the widgets; then the time in words ("Expected Mon 21:00", "Released …" after
/// the drop) and "Delayed from 20:00" when it moved, as the expanded island says them (D-57, UX audit #30:
/// "Expected" no longer appears twice, nor a struck-through time). Certainty is said in words only (D-40).
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
                    // A long provider shortens before its country does (D-20): "S12E104 · Paramount+ wi… · US".
                    CountryKeepingText(line: details)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ink(LiveActivityInk.muted))
                        .padding(.top, 2)
                        .accessibilityIdentifier("la-details")
                }
                Group {
                    if out {
                        // "Out now" over a stopped 0:00 read as one odd sentence (Chime's iPhone, 3 Nov): the words
                        // take the numbers' place, 0.7 times their size as in `CountdownText`, on their baseline and
                        // in their line's height, so the banner doesn't shrink at the drop. The hidden stand-in is
                        // plain text, not a timer: a timer asks for its widest value's width on the phone (D-57).
                        ZStack(alignment: Alignment(horizontal: .leading, vertical: .firstTextBaseline)) {
                            Text(verbatim: "0:00")
                                .font(NumeralStudy.night.font(size: 36))
                                .hidden()
                            Text(LiveActivityText.band(attributes, out: true))
                                .font(NumeralStudy.night.font(size: 36 * 0.7))
                                .foregroundStyle(LiveActivityInk.out)
                                .lineLimit(1)
                        }
                    } else {
                        LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 36)
                    }
                }
                .padding(.top, 10)
                .accessibilityIdentifier("la-countdown")
                timeLine
                    .padding(.top, 2)
            }
            Spacer(minLength: Self.artReserve)
        }
        .padding(.horizontal, Tokens.Space.m)
        // 12, and 10 over the countdown, leave a two-line title room inside 160 pt (158 with the longest name).
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { LiveActivityArtEdge(attributes: attributes, art: art) }
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LiveActivityText.accessibilityLabel(attributes, state: state, isStale: isStale, now: now,
                                                                formatter: formatter))
    }

    /// "Silo" in serif, then "+ 1 more" smaller when same-night drops merge. A long name takes two lines, then
    /// truncates (break-ui BU-9); "+ 1 more" stays. Under a moved time it keeps one line: two lines and "Delayed from"
    /// would take the banner past 160 pt.
    private var title: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: attributes.showName.trimmingCharacters(in: .whitespaces))
                .font(.system(size: 19, weight: .medium, design: .serif))
                .foregroundStyle(ink(LiveActivityInk.primary))
                .lineLimit(moved == nil ? 2 : 1)
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

    /// "Expected Fri 02:00" ("Released …" once out), then "Delayed from 01:00" in words when the time moved.
    private var timeLine: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LiveActivityText.outLine(attributes, dropDate: state.dropDate, out: out, formatter: formatter))
                .foregroundStyle(ink(LiveActivityInk.secondary))
                .accessibilityIdentifier("la-time")
            if let moved {
                Text(moved)
                    .foregroundStyle(ink(LiveActivityInk.muted))
                    .accessibilityIdentifier("la-previous")
            }
        }
        .font(.system(size: 13, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    /// "Delayed from 01:00" while the drop is ahead and its time moved; nil otherwise.
    private var moved: String? { out ? nil : LiveActivityText.movedLine(state, formatter: formatter) }

    /// Always-On lowers everything but the countdown a little further, as on the widgets.
    private func ink(_ color: Color) -> Color {
        WidgetInk.dimmed(color, when: dimmed)
    }
}
