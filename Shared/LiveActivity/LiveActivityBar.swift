import SwiftUI

/// The expanded island's thin bar along the bottom (#Tinder): it fills from when the activity started to the drop,
/// and is full at "Out now". The system draws and advances `ProgressView(timerInterval:)`, so it moves on its own.
struct LiveActivityBar: View {
    let window: ClosedRange<Date>
    let out: Bool
    var now = Date.now

    @Environment(\.liveActivityStaticProgress) private var drawsStatically

    var body: some View {
        Group {
            if out || drawsStatically {
                Capsule()
                    .fill(LiveActivityInk.track)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(LiveActivityInk.fill)
                                .frame(width: proxy.size.width * (out ? 1 : window.fraction(at: now)))
                        }
                    }
                    .frame(height: 4)
            } else {
                ProgressView(timerInterval: window, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.linear)
                .tint(LiveActivityInk.fill)
            }
        }
        .accessibilityHidden(true)
    }
}
