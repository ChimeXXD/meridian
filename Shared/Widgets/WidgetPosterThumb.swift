import SwiftUI
import WidgetKit

/// The small poster beside a show in the widgets' rows, in a poster's 2:3 shape. Without a poster yet it is a quiet
/// tile, so the rows stay aligned. Always-On hides the image.
struct WidgetPosterThumb: View {
    var image: UIImage?
    let height: CGFloat

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        RoundedRectangle(cornerRadius: height / 6)
            .fill(WidgetInk.tile)
            .overlay {
                if let image, !dimmed {
                    Image(uiImage: image)
                        .resizable()
                        .widgetAccentedRenderingMode(.desaturated)
                        .scaledToFill()
                }
            }
            .frame(width: height * 2 / 3, height: height)
            .clipShape(RoundedRectangle(cornerRadius: height / 6))
            .accessibilityHidden(true)
    }
}
