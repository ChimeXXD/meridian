import SwiftUI

/// Night Sky on the Home Screen widgets (D-38): a neutral near-black base (the art palette's `neutral.night`, so never
/// brown), white text in three strengths, and no colour outside the artwork. Lock Screen widgets use the system's
/// `.primary` and `.secondary` instead, because the system tints them.
enum WidgetInk {
    static let base = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.75)
    static let muted = Color.white.opacity(0.55)
    /// Where a thumbnail would be when a show has no art yet.
    static let tile = Color.white.opacity(0.08)

    /// Always-On lowers everything but the countdown a little further (UI-BRIEF §6.1).
    static func dimmed(_ color: Color, when reduced: Bool) -> Color {
        reduced ? color.opacity(0.85) : color
    }
}
