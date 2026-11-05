import SwiftUI

/// The app's one press feedback (EA-10, AD-1, AD-13): the press shows at once, the release eases out over 0.16 s, so a
/// tap feels answered without the label lagging behind the finger. Each role picks only how much it gives: the hero
/// dims (a 400 pt scale would swim), rows and the quiet grid shrink to 0.98, posters, chips and buttons to 0.97.
struct PressStyle: ButtonStyle {
    var scale: CGFloat = 1
    var opacity: Double = 1

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.pressed(configuration.isPressed, scale: scale, opacity: opacity)
    }
}

extension ButtonStyle where Self == PressStyle {
    /// Upcoming's hero and spotlight: opacity only.
    static var heroPress: PressStyle { PressStyle(opacity: 0.8) }
    /// Upcoming's rows and its quiet grid.
    static var rowPress: PressStyle { PressStyle(scale: 0.98) }
    /// Posters, chips, Follow and the (+), and the outlined capsules.
    static var controlPress: PressStyle { PressStyle(scale: 0.97) }
}

extension View {
    /// Instant on press, a 0.16 s ease out on release: `nil` while pressed, so nothing animates toward the press.
    func pressed(_ isPressed: Bool, scale: CGFloat = 1, opacity: Double = 1) -> some View {
        scaleEffect(isPressed ? scale : 1)
            .opacity(isPressed ? opacity : 1)
            .animation(isPressed ? nil : .easeOut(duration: 0.16), value: isPressed)
    }
}

/// Show detail's grouped card rows (Report, Unfollow): a lighter fill while pressed, as Settings' rows do, instead of
/// a scale inside a card that stays put. On the card's white 0.08, so a pressed row reads about white 0.16.
struct CardRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.white.opacity(configuration.isPressed ? 0.08 : 0))
            .animation(configuration.isPressed ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
