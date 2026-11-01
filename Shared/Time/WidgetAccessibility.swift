import Foundation

/// The full phrase VoiceOver reads for a widget or Live Activity (CLAUDE.md, SPEC: "Silo, in 2 days 4 hours, Apple
/// TV"; "House of the Dragon, in 3 hours, HBO US, no official stream in your country").
///
/// Day 4 contract: this signature is fixed so the widget views (D4-3, D4-4) and the phrase (D4-5) can be built at once.
/// The body is a placeholder until D4-5 fills it in.
enum WidgetAccessibility {
    /// Nil `drop` means nothing is followed or scheduled.
    static func label(for drop: Drop?, now: Date, formatter: DropFormatter = DropFormatter()) -> String {
        drop?.showName ?? "Airstamp"
    }
}
