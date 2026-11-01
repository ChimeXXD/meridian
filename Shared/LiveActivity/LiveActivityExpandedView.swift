import SwiftUI
import UIKit

/// The expanded Dynamic Island's regions (SPEC §6, UI-BRIEF §6.2, #Tinder): the show's name in serif over
/// "S2E5 · Apple TV" on the leading side; the show's art, rounded, top-right; and along the bottom the plain-words
/// label with the big countdown ("Expected in 1:59:59", becoming a big "Out now" at the drop), over a thin bar that fills from when
/// the activity started to the drop, with the local time at its end and the old one struck through after a delay.
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

    private var out: Bool { LiveActivityText.isOut(state, isStale: isStale, now: now) }

    var body: some View {
        content
            .environment(\.colorScheme, .dark)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LiveActivityText.accessibilityLabel(attributes, state: state, isStale: isStale,
                                                                    now: now, formatter: formatter))
    }

    @ViewBuilder private var content: some View {
        switch region {
        case .leading: title
        case .trailing: artwork
        case .bottom: countdown
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if out {
                    // "Out now 0:00" would read as one odd sentence: at the drop the words take the numbers' place.
                    Text(LiveActivityText.band(attributes, out: true))
                        .font(.system(size: 34, weight: NumeralStudy.night.weight, design: .serif))
                        .foregroundStyle(LiveActivityInk.out)
                        .lineLimit(1)
                } else {
                    Text(LiveActivityText.band(attributes, out: false))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LiveActivityInk.secondary)
                        .lineLimit(1)
                        .fixedSize()
                    LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 34)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("la-expanded-countdown")
            HStack(spacing: 8) {
                LiveActivityBar(window: attributes.window(until: state.dropDate), out: out, now: now)
                if let previous = LiveActivityText.previousTime(state, formatter: formatter) {
                    Text(previous)
                        .strikethrough()
                        .foregroundStyle(LiveActivityInk.muted)
                        .fixedSize()
                }
                Text(formatter.localTime(state.dropDate))
                    .foregroundStyle(LiveActivityInk.secondary)
                    .fixedSize()
            }
            .font(.system(size: 13, weight: .medium).monospacedDigit())
            .accessibilityIdentifier("la-expanded-bar")
        }
    }
}
