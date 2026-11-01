import SwiftUI

/// The expanded Dynamic Island's regions (SPEC §6, UI-BRIEF §6.2): the show's name in serif over its episode on the
/// leading side; the countdown parked top-right under a caption that carries the certainty ("Expected in", #140
/// Moonlitt, #141 Tide Guide) and flips to "Out now"; and "Apple TV · 02:00" along the bottom, with the old time
/// struck through after a delay.
struct LiveActivityExpandedView: View {
    enum Region: Sendable, CaseIterable { case leading, trailing, bottom }

    let region: Region
    let attributes: DropActivityAttributes
    let state: DropActivityAttributes.ContentState
    var isStale = false
    var now = Date.now
    var formatter = DropFormatter()

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
        case .trailing: countdown
        case .bottom: meta
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LiveActivityText.title(attributes))
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundStyle(LiveActivityInk.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if !attributes.episodeLabel.isEmpty {
                Text(attributes.episodeLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LiveActivityInk.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("la-expanded-title")
    }

    private var countdown: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(LiveActivityText.band(attributes, out: out))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(out ? LiveActivityInk.primary : LiveActivityInk.muted)
                .lineLimit(1)
            LiveActivityCountdown(dropDate: state.dropDate, now: now, size: 28, alignment: .trailing)
                .frame(maxWidth: 120, alignment: .trailing)
        }
        .accessibilityIdentifier("la-expanded-countdown")
    }

    private var meta: some View {
        HStack(spacing: 6) {
            Text(LiveActivityText.meta(attributes, dropDate: state.dropDate, formatter: formatter))
                .foregroundStyle(LiveActivityInk.secondary)
            if let previous = LiveActivityText.previousTime(state, formatter: formatter) {
                Text(previous)
                    .strikethrough()
                    .foregroundStyle(LiveActivityInk.muted)
            }
            Spacer(minLength: 0)
        }
        .font(.system(size: 13, weight: .medium))
        .lineLimit(1)
        .accessibilityIdentifier("la-expanded-meta")
    }
}
