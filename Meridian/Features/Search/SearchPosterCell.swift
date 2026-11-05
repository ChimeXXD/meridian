import SwiftUI

/// One cell of Search's poster grid: the poster, the title and its meta lines open the show's page as one button that
/// gives under the finger (AD-1); the round follow button sits on the poster's corner, outside that button, so it
/// still follows in one tap. The parts keep their own IDs (`<id>-title`, `<id>-meta`, `<id>-follow`) for the screen
/// checks.
struct SearchPosterCell<Meta: View>: View {
    let result: SearchResult
    let id: String
    let meta: Meta
    let following: Bool
    let onOpen: () -> Void
    /// The (+) or ✓: follows, or asks before unfollowing.
    let onFollow: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                PosterImage(url: result.poster, cornerRadius: 8)
                    .aspectRatio(2 / 3, contentMode: .fit)
                Text(result.title)
                    .font(.subheadline.weight(.medium))  // a step above its 12 pt info lines (UX audit #26)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .multilineTextAlignment(.leading)
                    .accessibilityIdentifier("\(id)-title")
                // Two lines a part, so a long network ("Amazon Prime Video") can't push its country out of the cell.
                meta
                    .font(.caption)
                    .foregroundStyle(NightInk.muted)
                    .multilineTextAlignment(.leading)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .accessibilityIdentifier("\(id)-meta")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.controlPress)
        .accessibilityHint("Opens the show")
        // The poster is the cell's top, so its top-trailing corner is the cell's.
        .overlay(alignment: .topTrailing) {
            SearchFollowButton(title: result.title, following: following, size: 32, action: onFollow)
                .accessibilityIdentifier("\(id)-follow")
                .padding(Tokens.Space.xxs)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(id)
    }
}

/// The poster's round follow button: a dark (+) with a hairline, or a white ✓ once followed. The symbol turns over
/// with `.replace` rather than snapping (AD-5), and the circle gives under the finger like the poster.
struct SearchFollowButton: View {
    let title: String
    let following: Bool
    var size: CGFloat = 32
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: following ? "checkmark" : "plus")
                .contentTransition(.symbolEffect(.replace))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(following ? .black : .white)
                .frame(width: size, height: size)
                .background(following ? AnyShapeStyle(.white) : AnyShapeStyle(.black.opacity(0.55)), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(following ? 0 : 0.35)))
                .animation(.snappy(duration: 0.25), value: following)
                // The 44 pt tap area around the 32 pt circle.
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.controlPress)
        .accessibilityLabel(following ? "Following \(title)" : "Follow \(title)")
    }
}
