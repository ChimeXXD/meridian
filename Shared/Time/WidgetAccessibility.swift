import Foundation

/// The full phrase VoiceOver reads for a widget or Live Activity (CLAUDE.md, SPEC: "Silo, in 2 days 4 hours, Apple
/// TV"; "House of the Dragon, in 3 hours, HBO US, no official stream in your country").
///
/// The show, then when, then where. The certainty is said in words, as `ReleaseWording` does (D-40): an estimate is
/// "expected", an AniList time "airs in Japan". The provider is named, never "on HBO" (D-20), and the episode title is
/// left out, as on the widget (spoiler-safe).
enum WidgetAccessibility {
    /// Nil `drop` means nothing is followed or scheduled.
    static func label(for drop: Drop?, now: Date, formatter: DropFormatter = DropFormatter()) -> String {
        guard let drop else { return "Nothing scheduled for your shows" }
        var parts = [drop.showName, when(drop, now: now, formatter: formatter)]
        if let provider = drop.provider {
            // "HBO · US" is read "HBO US": the dot is for the eye.
            parts.append([provider.name, provider.countryCode].compactMap { $0 }.joined(separator: " "))
            if provider.noOfficialStream { parts.append("no official stream in your country") }
        }
        return parts.joined(separator: ", ")
    }

    /// "in 2 days 4 hours", "expected in 3 hours", "airs in Japan in 5 hours 30 minutes", "out now",
    /// "out Thu 19 Nov, time not announced".
    private static func when(_ drop: Drop, now: Date, formatter: DropFormatter) -> String {
        switch CountdownFormatter.state(drop: drop.date, confidence: drop.confidence, now: now) {
        case .dateOnly, .released:
            return lowercasingFirst(ReleaseWording.outLine(drop, now: now, formatter: formatter))
        case .outNow:
            if case .anilist = drop.source { return "just aired in Japan" }
            return drop.confidence == .exact ? "out now" : "expected now"
        case .ticking, .coarse:
            let left = "in " + CountdownFormatter.spokenText(CountdownFormatter.parts(from: now, to: drop.date, maxUnits: 2))
            if case .anilist = drop.source { return "airs in Japan \(left)" }
            return drop.confidence == .exact ? left : "expected \(left)"
        }
    }

    /// "Out Thu 19 Nov, …" → "out Thu 19 Nov, …", so the line sits mid-sentence. "Japan" keeps its capital.
    private static func lowercasingFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.lowercased() + text.dropFirst()
    }
}
