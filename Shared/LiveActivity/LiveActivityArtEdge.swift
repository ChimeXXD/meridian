import SwiftUI
import UIKit

/// The Lock Screen banner's background (#Duolingo): the night base, with the show's key art on the right edge, full
/// height, fading leftwards into the base so the countdown sits on artwork rather than a flat card. Without art it is
/// the base with the show's initial drawn large and faint on the right, so the banner still looks designed. Always-On
/// hides both, as the widgets hide their art.
struct LiveActivityArtEdge: View {
    let attributes: DropActivityAttributes
    var art: UIImage?
    /// How much of the width the art covers, from the right, by default.
    static let defaultShare: CGFloat = 0.44
    /// How much of the width the art covers, from the right.
    var share: CGFloat = Self.defaultShare

    @Environment(\.isLuminanceReduced) private var dimmed

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                LiveActivityInk.base
                if dimmed {
                    EmptyView()
                } else if let art {
                    Image(uiImage: art)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width * share, height: proxy.size.height)
                        .clipped()
                        .overlay {
                            LinearGradient(stops: [.init(color: LiveActivityInk.base, location: 0),
                                                   .init(color: LiveActivityInk.base.opacity(0.75), location: 0.3),
                                                   .init(color: LiveActivityInk.base.opacity(0.15), location: 0.75),
                                                   .init(color: .clear, location: 1)],
                                           startPoint: .leading, endPoint: .trailing)
                        }
                } else {
                    Text(LiveActivityText.monogram(attributes))
                        .font(.system(size: proxy.size.height * 1.1, weight: .light, design: .serif))
                        .foregroundStyle(LiveActivityInk.primary)
                        .fixedSize()
                        // On the view, not the ink, so an emoji initial ("💍") is as faint as a letter.
                        .opacity(0.07)
                        .offset(x: proxy.size.height * 0.08, y: proxy.size.height * 0.12)
                        .padding(.trailing, Tokens.Space.m)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }
}
