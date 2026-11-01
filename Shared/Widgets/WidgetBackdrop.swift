import SwiftUI
import UIKit

/// The Home Screen widgets' background: the night base, with the show's small art fading into it when the app has
/// saved one (D-38). Without art it is the plain base, which is the design, not a gap. It sits in
/// `containerBackground`, so tinted and clear Home Screens remove it and Always-On never shows the art.
struct WidgetBackdrop: View {
    var art: UIImage?

    var body: some View {
        ZStack(alignment: .top) {
            WidgetInk.base
            if let art {
                Image(uiImage: art)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipped()
                    .accessibilityHidden(true)
                // Fade into the base where the countdown sits, and darken the top for the title.
                LinearGradient(stops: [.init(color: .black.opacity(0.45), location: 0),
                                       .init(color: WidgetInk.base.opacity(0.2), location: 0.3),
                                       .init(color: WidgetInk.base, location: 0.72)],
                               startPoint: .top, endPoint: .bottom)
            }
        }
    }
}
