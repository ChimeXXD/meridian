import SwiftUI
import UIKit

/// The expanded Dynamic Island's regions (SPEC §6, UI-BRIEF §6.2): the show's name in serif over "S2E5 · Apple TV" on
/// the leading side; the show's art, rounded, top-right; and along the bottom one line laid out like Upcoming's rows:
/// the time in words ("Expected Wed 23:00") with the countdown beside it at the rows' size, "Delayed from 22:00"
/// under the words when the time moved, and a gold "Out now" in the numbers' place at the drop. No progress bar: its
/// fill counted from when the activity happened to start, which told Chime nothing (2 Nov).
struct LiveActivityExpandedView: View {
    enum Region: Sendable, CaseIterable { case leading, trailing, bottom }

    let region: Region
    let attributes: DropActivityAttributes
    let state: DropActivityAttributes.ContentState
    /// The wide key art, cropped square; the poster when there's none.
    var art: UIImage?
    var poster: UIImage?
    var isStale = false
    var now = Date.now
    var formatter = DropFormatter()

    static let artSize: CGFloat = 50
    /// Wide enough for "5:59:59" (the longest lead time is 6 hours) in 24 pt serif digits, as the compact timer's is.
    static let timerWidth: CGFloat = 96

    private var out: Bool { LiveActivityText.isOut(state, isStale: isStale, now: now) }

    var body: some View {
        content
            .environment(\.colorScheme, .dark)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LiveActivityText.accessibilityLabel(attributes, state: state, isStale: isStale,
                                                                    now: now, formatter: formatter))
    }

    /// The island starts every region at the same edge, so equal side insets line the bottom line's words up under
    /// the title and its countdown under the art (Chime, 2 Nov: the bottom's 16 against the top's 4 left them 12 pt in).
    @ViewBuilder private var content: some View {
        switch region {
        case .leading: title.padding(.leading, Tokens.Space.xxs)
        case .trailing: artwork.padding(.trailing, Tokens.Space.xxs)
        case .bottom:
            countdown
                .padding(.horizontal, Tokens.Space.xxs)
                .padding(.top, Tokens.Space.xxs)
                .padding(.bottom, Tokens.Space.xs)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LiveActivityText.title(attributes))
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(LiveActivityInk.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            let details = LiveActivityText.details(attributes)
            if !details.isEmpty {
                Text(details)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LiveActivityInk.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("la-expanded-title")
    }

    @ViewBuilder private var artwork: some View {
        Group {
            if let image = art ?? poster {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.artSize, height: Self.artSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                LiveActivityPosterMark(attributes: attributes, size: Self.artSize)
            }
        }
        .accessibilityHidden(true)
        .accessibilityIdentifier("la-expanded-art")
    }

    private var countdown: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.s) {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text(LiveActivityText.outLine(attributes, dropDate: state.dropDate, out: out, formatter: formatter))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LiveActivityInk.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityIdentifier("la-expanded-time")
                if !out, let moved = LiveActivityText.movedLine(state, formatter: formatter) {
                    Text(moved)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LiveActivityInk.muted)
                        .lineLimit(1)
                        .accessibilityIdentifier("la-expanded-moved")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if out {
                    // "Out now 0:00" would read as one odd sentence: at the drop the words take the numbers' place.
                    Text(LiveActivityText.band(attributes, out: true))
                        .font(.system(size: 24, weight: NumeralStudy.night.weight, design: .serif))
                        .foregroundStyle(LiveActivityInk.out)
                        .lineLimit(1)
                        .fixedSize()
                } else {
                    // A set width, never `fixedSize`: on the phone a timer asks for the width of its widest value,
                    // which pushed the whole line out of the island and left it blank (Chime's iPhone, 2 Nov).
                    LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 24, alignment: .trailing)
                        // A delay can push the drop past the 6-hour lead ("10:59:59"): shrink, don't cut the digits.
                        .minimumScaleFactor(0.75)
                        .frame(width: Self.timerWidth, alignment: .trailing)
                }
            }
            .accessibilityIdentifier("la-expanded-countdown")
        }
    }
}
