import SwiftUI

/// The one-screen welcome (SPEC §1, UI-BRIEF §5.1): what Meridian answers, the detected zone, and a way to follow
/// the first show. Shown once, until you follow a show or tap "Not now". The widget prompt joins with the widgets.
/// Shows airing this week drift across the top and fade into night, with the headline over the fade (Chime's picks,
/// 2 Nov: Mindvalley, Nike, HBO Max). Without art (offline, or too little) the screen is the plain night it was,
/// until the art arrives on a later return to the app.
struct WelcomeView: View {
    let client: TVmazeClient
    let anilist: AniListClient
    let rules: RulesFile
    var formatter = DropFormatter()
    let onFind: () -> Void
    let onLater: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var wall: WelcomeWall?
    /// The mark grows with the wordmark under Dynamic Type (36 at the default size, beside a 22 pt name).
    @ScaledMetric(relativeTo: .title2) private var markHeight: CGFloat = 36

    private let night = ArtworkPalette.neutral.night.color

    var body: some View {
        // Two groups (unslop, 2 Nov): the brand and its promise (logo, 16, headline, 12, zone), then 32 to the actions.
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            lockup
            Text("How long until your next episode, in your time zone, and where it's on")
                .font(.system(size: 34, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Tokens.Space.m)
            Text("Times shown for \(ReleaseWording.zoneSummary(formatter, at: .now))")
                .font(.body.weight(.medium))
                .foregroundStyle(NightInk.secondary)
                .accessibilityIdentifier("welcome-zone")
                .padding(.top, Tokens.Space.s)
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
            .padding(.top, Tokens.Space.xl)
        }
        .padding(.horizontal, Tokens.Space.l)
        .padding(.bottom, Tokens.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .top) {
            GeometryReader { proxy in
                if let wall {
                    // Under the status bar, over the top 60% of the screen; the headline sits on its fade.
                    WelcomeWallView(wall: wall, night: night)
                        .frame(height: (proxy.size.height + proxy.safeAreaInsets.top) * 0.6)
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(night)
        .environment(\.colorScheme, .dark)
        // Tried again each time the app comes back, so a first launch offline gets its art once the network does.
        .task(id: scenePhase) {
            guard scenePhase == .active, wall == nil,
                  let loaded = await WelcomeWall.load(client: client, anilist: anilist, rules: rules) else { return }
            withAnimation(.easeOut(duration: 0.35)) { wall = loaded }
        }
    }

    /// The logo on the night, never over the art (the design system's "Using the mark"): the Longitudes mark and the
    /// name in the serif, read by VoiceOver as one "Meridian".
    private var lockup: some View {
        HStack(spacing: Tokens.Space.xs) {
            MeridianMark().frame(width: markHeight * MeridianMark.widthRatio, height: markHeight)
            Text("Meridian")
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Color(uiColor: Tokens.starlight))
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("welcome-logo")
    }
}
