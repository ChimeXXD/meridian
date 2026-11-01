import SwiftUI

/// Night Sky on the Live Activity (D-38): a near-black base, a shade deeper than the widgets' so the banner reads as
/// night on any wallpaper rather than a grey card, and the widgets' white inks. No colour outside the show's art: the
/// ring and the bar fill in white. Nothing here says how sure a time is; that is always in words (D-40).
enum LiveActivityInk {
    static let base = Color(red: 0.05, green: 0.05, blue: 0.055)
    static let primary = WidgetInk.primary
    static let secondary = WidgetInk.secondary
    static let muted = WidgetInk.muted
    /// The ring's and the bar's fill, and the empty part they run along.
    static let fill = Color.white
    static let track = Color.white.opacity(0.18)
    /// The disc behind the monogram when there's no poster.
    static let disc = Color.white.opacity(0.16)
    /// The Dynamic Island's outline.
    static let keyline = Color.white.opacity(0.35)
}
