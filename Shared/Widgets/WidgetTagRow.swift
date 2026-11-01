import SwiftUI

/// The Home Screen widgets' top line over the art: where the hero is on, tagged on the left, and "+3 more this week"
/// on the right when there are shows the widget can't fit. VoiceOver reads the "more" tag; the provider is already in
/// the hero's phrase.
struct WidgetTagRow: View {
    var provider: String?
    var more: String?

    var body: some View {
        HStack(spacing: Tokens.Space.xs) {
            if let provider {
                WidgetTag(text: provider).accessibilityHidden(true)
            }
            Spacer(minLength: 0)
            if let more {
                WidgetTag(text: more).accessibilityIdentifier("widget-more")
            }
        }
    }
}
