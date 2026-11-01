import SwiftUI
import UIKit

/// The show's mark in the Dynamic Island: its poster cropped square, in a rounded square (compact leading, #Instagram)
/// or a circle (inside the minimal ring, #Yazio). Without a poster (the Debug show, or art not saved yet) it is the
/// show's initial in serif on a filled dark disc, "S" for Silo. Decorative: the view around it carries the label.
struct LiveActivityPosterMark: View {
    enum Shape: Sendable { case rounded, circle }

    let attributes: DropActivityAttributes
    var poster: UIImage?
    var size: CGFloat = 24
    var shape: Shape = .rounded

    var body: some View {
        Group {
            if let poster {
                Image(uiImage: poster)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(clip)
            } else {
                Text(LiveActivityText.monogram(attributes))
                    .font(.system(size: size * 0.55, weight: .semibold, design: .serif))
                    .foregroundStyle(LiveActivityInk.primary)
                    .frame(width: size, height: size)
                    .background(LiveActivityInk.disc, in: Circle())
            }
        }
        .accessibilityHidden(true)
    }

    private var clip: AnyShape {
        switch shape {
        case .rounded: AnyShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
        case .circle: AnyShape(Circle())
        }
    }
}
