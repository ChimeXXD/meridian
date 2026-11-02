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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wall: WelcomeWall?
    /// The mark grows with the wordmark under Dynamic Type (36 at the default size, beside a 22 pt name).
    @ScaledMetric(relativeTo: .title2) private var markHeight: CGFloat = 36

    private let night = ArtworkPalette.neutral.night.color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Scrolls only when it doesn't fit (the accessibility sizes, small phones: UX audit #9); otherwise the text sits
        // at the bottom as before.
        GeometryReader { outer in
            ScrollView {
                content.frame(maxWidth: .infinity, minHeight: outer.size.height, alignment: .bottomLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .background(alignment: .top) {
            GeometryReader { proxy in
                // Under the status bar, over the top 60% of the screen; the headline sits on its fade. At the
                // accessibility sizes the text fills the screen and the logo would sit on the art, so Welcome is the
                // plain night it is offline (UX audit #9).
                if let wall, !dynamicTypeSize.isAccessibilitySize {
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
            guard scenePhase == .active, wall == nil, !dynamicTypeSize.isAccessibilitySize,
                  let loaded = await WelcomeWall.load(client: client, anilist: anilist, rules: rules) else { return }
            // Reduce Motion: the wall appears at once, as the art does everywhere else (ArtworkLoaderView).
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) { wall = loaded }
        }
    }

    /// Two groups (unslop, 2 Nov): the brand and its promise (logo, 16, headline, 12, zone), then 32 to the actions.
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            lockup
            Text("How long until your next episode, in your time zone, and where it's on")
                .serif(34, relativeTo: .largeTitle)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Tokens.Space.m)
            Text("Times shown for \(ReleaseWording.zoneSummary(formatter, at: .now))")
                .font(.body.weight(.medium))
                .foregroundStyle(NightInk.secondary)
                .accessibilityIdentifier("welcome-zone")
                .padding(.top, Tokens.Space.s)
            VStack(spacing: Tokens.Space.s) {
                Button(action: onFind) {
                    Text("Find a show").frame(maxWidth: .infinity).frame(minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .accessibilityIdentifier("welcome-find")
                Button("Not now", action: onLater)
                    .foregroundStyle(NightInk.secondary)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("welcome-later")
            }
            .padding(.top, Tokens.Space.xl)
        }
        .padding(.horizontal, Tokens.Space.l)
        .padding(.bottom, Tokens.Space.l)
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
