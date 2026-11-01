import Foundation

/// The Live Activity's words, apart from the views so the scheduler's alert and every presentation read the same
/// (SPEC §6, UI-BRIEF §6.2). Certainty is in words (D-40); the provider keeps its country (D-20).
enum LiveActivityText {
    /// The title: "Silo", or "Silo + 1 more" when same-night drops are merged.
    static func title(_ attributes: DropActivityAttributes) -> String {
        attributes.showName // CONTRACT: Lane A implements.
    }

    /// The breadcrumb above the countdown: "Silo · S2E5 · Apple TV · US".
    static func breadcrumb(_ attributes: DropActivityAttributes) -> String {
        attributes.showName // CONTRACT: Lane A implements.
    }

    /// The absolute local time line: "Out Fri 02:00", "Expected Wed 23:00".
    static func timeLine(_ attributes: DropActivityAttributes, dropDate: Date, formatter: DropFormatter) -> String {
        "" // CONTRACT: Lane A implements.
    }

    /// The alert when the activity starts: title "Silo", body "Starts in 2 hours · 02:00 · Apple TV" (SPEC §6
    /// "Silo starts in 2 hours · 02:00 · Apple TV", split into the alert's title and body).
    static func alert(_ attributes: DropActivityAttributes, leadMinutes: Int, dropDate: Date,
                      formatter: DropFormatter) -> (title: String, body: String) {
        (attributes.showName, "") // CONTRACT: Lane A implements.
    }

    /// The VoiceOver phrase, built like the widgets' (CLAUDE.md accessibility rule): "Silo, expected in 2 hours,
    /// Apple TV".
    static func accessibilityLabel(_ attributes: DropActivityAttributes, state: DropActivityAttributes.ContentState,
                                   isStale: Bool, now: Date, formatter: DropFormatter) -> String {
        attributes.showName // CONTRACT: Lane A implements.
    }
}
