import SwiftUI

/// The app's primary button (UX audit #27): a white capsule at least 50 pt tall with black `.headline` text, dimming a
/// little while pressed. Welcome's and empty Upcoming's "Find a show" use it; the show page's Follow keeps its own two
/// states (white "Follow", outlined "Following") in the same shape and type.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(.white, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
