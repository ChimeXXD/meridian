import SwiftUI

/// The one-screen welcome (SPEC §1, UI-BRIEF §5.1): what Meridian answers, the detected zone, and a way to follow
/// the first show. Shown once, until you follow a show or tap "Not now". The widget prompt joins with the widgets.
struct WelcomeView: View {
    var formatter = DropFormatter()
    let onFind: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            Spacer()
            Text("Meridian")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NightInk.muted)
            Text("How long until your next episode, in your time zone, and where it's on")
                .font(.system(size: 34, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
            Text("Times shown for \(ReleaseWording.zoneSummary(formatter, at: .now))")
                .font(.body.weight(.medium))
                .foregroundStyle(NightInk.secondary)
                .accessibilityIdentifier("welcome-zone")
            Spacer()
            VStack(spacing: Tokens.Space.s) {
                Button(action: onFind) {
                    Text("Find a show").frame(maxWidth: .infinity).frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .accessibilityIdentifier("welcome-find")
                Button("Not now", action: onLater)
                    .foregroundStyle(NightInk.secondary)
                    .frame(height: 44)
                    .accessibilityIdentifier("welcome-later")
            }
        }
        .padding(.horizontal, Tokens.Space.l)
        .padding(.bottom, Tokens.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArtworkPalette.neutral.night.color)
        .environment(\.colorScheme, .dark)
    }
}
