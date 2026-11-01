import SwiftUI

/// The minimal island's ring (#Yazio): it fills from when the activity started to the drop, around the show's poster
/// or initial, and is full at "Out now". `ProgressView(timerInterval:)` is drawn and advanced by the system, so the
/// ring moves with no timeline and no app running.
struct LiveActivityRing<Center: View>: View {
    let window: ClosedRange<Date>
    let out: Bool
    var now = Date.now
    var diameter: CGFloat = 24
    @ViewBuilder var center: Center

    @Environment(\.liveActivityStaticProgress) private var drawsStatically

    var body: some View {
        ZStack {
            if out || drawsStatically {
                Circle()
                    .stroke(LiveActivityInk.track, lineWidth: Self.lineWidth)
                Circle()
                    .trim(from: 0, to: out ? 1 : window.fraction(at: now))
                    .stroke(LiveActivityInk.fill, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            } else {
                ProgressView(timerInterval: window, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(LiveActivityInk.fill)
            }
            center
        }
        .padding(Self.lineWidth / 2)
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }

    /// The ring's stroke, and the room the centre leaves inside it.
    static var lineWidth: CGFloat { 2.5 }
    static var inset: CGFloat { lineWidth + 2 }
}
