import SwiftUI
import UIKit

/// The Home Screen widgets' background: the night base, with the show's art across the top fading into it when the
/// app has saved some (D-38). The top of the art stays clear and the words sit where it has faded (#Tripsy,
/// #Apple TV). Without art it is the plain base, which is the design, not a gap. It sits in `containerBackground`, so
/// tinted and clear Home Screens remove it and Always-On never shows the art.
struct WidgetBackdrop: View {
    var art: UIImage?
    /// How much of the height the art covers, from the top: all of it on the small and medium widgets, the hero's
    /// share on the large one.
    var coverage: CGFloat = 1

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                WidgetInk.base
                if let art {
                    Image(uiImage: art)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height * coverage, alignment: .top)
                        .clipped()
                        .overlay {
                            LinearGradient(stops: [.init(color: .clear, location: 0.25),
                                                   .init(color: WidgetInk.base.opacity(0.7), location: 0.5),
                                                   .init(color: WidgetInk.base, location: 0.75)],
                                           startPoint: .top, endPoint: .bottom)
                        }
                        .accessibilityHidden(true)
                }
            }
        }
    }
}
