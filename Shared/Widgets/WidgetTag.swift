import SwiftUI

/// A small tag in the Home Screen widgets' top corners over the art (#Tripsy's badges): where the show is on ("HBO ·
/// US") on the left, and "+3 more this week" on the right when shows don't fit. A dark capsule keeps it readable on any
/// art and on the plain base.
struct WidgetTag: View {
    let text: String

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(WidgetInk.dimmed(WidgetInk.primary, when: dimmed))
            .lineLimit(1).minimumScaleFactor(0.8)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.black.opacity(0.45), in: Capsule())
    }
}
