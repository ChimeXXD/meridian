import SwiftUI

/// Where a show is on, as a small tag in the Home Screen widgets' top corner over the art (#Tripsy's badges): "HBO · US",
/// "Apple TV". A dark capsule keeps it readable on any art and on the plain base.
struct WidgetProviderTag: View {
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
