import SwiftUI

/// Night Sky on the Live Activity (D-38): the widgets' near-black base and white inks, plus one pale moonlight tint
/// for the Dynamic Island's timer and keyline. The tint is decoration only; it never says how sure a time is, which is
/// always in words (D-40).
enum LiveActivityInk {
    static let base = WidgetInk.base
    static let primary = WidgetInk.primary
    static let secondary = WidgetInk.secondary
    static let muted = WidgetInk.muted
    /// The header band's fill before the drop; at the drop it turns white with dark words (#146 Strava).
    static let band = Color.white.opacity(0.10)
    static let bandOut = Color.white
    static let bandOutText = WidgetInk.base
    /// The compact timer and the island's keyline.
    static let moonlight = Color(red: 0.80, green: 0.86, blue: 1.0)
}
