import Foundation

/// The Live Activity's words, apart from the views so the scheduler's alert and every presentation read the same
/// (SPEC §6, UI-BRIEF §6.2). Certainty is in words (D-40); the provider keeps its country (D-20).
enum LiveActivityText {
    /// The title: "Silo", or "Silo + 1 more" when same-night drops are merged.
    static func title(_ attributes: DropActivityAttributes) -> String {
        guard let others = more(attributes) else { return attributes.showName }
        return "\(attributes.showName) \(others)"
    }

    /// The line under the title: "S2E5 · Apple TV · US"; "" when neither is known.
    static func details(_ attributes: DropActivityAttributes) -> String {
        [attributes.episodeLabel, attributes.provider ?? ""]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    /// The absolute local time line: "Out Fri 02:00", "Expected Wed 23:00".
    static func timeLine(_ attributes: DropActivityAttributes, dropDate: Date, formatter: DropFormatter) -> String {
        "\(attributes.verb.rawValue) \(formatter.weekdayTime(dropDate))"
    }

    /// The alert when the activity starts: title "Silo", body "Starts in 2 hours · 02:00 · Apple TV" (SPEC §6
    /// "Silo starts in 2 hours · 02:00 · Apple TV", split into the alert's title and body).
    ///
    /// Only a sure time "starts"; an estimate says "Expected in 2 hours" and an anime "Airs in Japan in 2 hours", so
    /// the alert never claims more than its source (D-40, CLAUDE.md rule 3).
    static func alert(_ attributes: DropActivityAttributes, leadMinutes: Int, dropDate: Date,
                      formatter: DropFormatter) -> (title: String, body: String) {
        let lead = LeadTime.phrase(minutes: leadMinutes)
        let opener = attributes.verb == .out ? "Starts in \(lead)" : "\(attributes.verb.rawValue) in \(lead)"
        let body = [opener, formatter.localTime(dropDate), provider(attributes)].compactMap(\.self)
            .joined(separator: " · ")
        return (title(attributes), body)
    }

    /// The VoiceOver phrase, built like the widgets' (CLAUDE.md accessibility rule): "Silo, expected in 2 hours,
    /// Apple TV".
    static func accessibilityLabel(_ attributes: DropActivityAttributes, state: DropActivityAttributes.ContentState,
                                   isStale: Bool, now: Date, formatter: DropFormatter) -> String {
        let out = isOut(state, isStale: isStale, now: now)
        var parts = [spokenTitle(attributes), when(attributes, state: state, out: out, now: now)]
        if !out, let previous = state.delayedFrom, previous != state.dropDate {
            let moved = previous < state.dropDate ? "delayed from" : "moved from"
            parts.append("\(moved) \(formatter.weekdayTime(previous))")
        }
        // "HBO · US" is read "HBO US": the dot is for the eye.
        if let label = provider(attributes) { parts.append(label.replacingOccurrences(of: " · ", with: " ")) }
        if attributes.noOfficialStream { parts.append("no official stream in your country") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Pieces the views share

    /// Whether the views show "Out now": the content went stale at the drop (SPEC §6 Staleness), the app moved it to
    /// `.outNow`, or the drop has simply passed.
    static func isOut(_ state: DropActivityAttributes.ContentState, isStale: Bool, now: Date) -> Bool {
        isStale || state.phase == .outNow || state.dropDate <= now
    }

    /// The plain-words band: "Out in", "Expected in", "Airs in Japan in", flipping to "Out now" at the drop (D-49).
    /// The small family shows it over the countdown, which stays at 0:00; the Lock Screen banner and the island put
    /// "Out now" in the numbers' place.
    static func band(_ attributes: DropActivityAttributes, out: Bool) -> String {
        out ? "Out now" : "\(attributes.verb.rawValue) in"
    }

    /// "+ 1 more" when same-night drops are merged; nil for one drop.
    static func more(_ attributes: DropActivityAttributes) -> String? {
        attributes.dropIDs.count > 1 ? "+ \(attributes.dropIDs.count - 1) more" : nil
    }

    /// The time it was listed for before a delay, struck through next to the new one: "01:00", or "Thu 23:00" when it
    /// was another day. Nil when it hasn't moved.
    static func previousTime(_ state: DropActivityAttributes.ContentState, formatter: DropFormatter) -> String? {
        guard let previous = state.delayedFrom, previous != state.dropDate else { return nil }
        return formatter.time(previous, besides: state.dropDate)
    }

    /// The expanded island's time in words: "Expected Wed 23:00", as the Lock Screen's time line says it. At the drop
    /// a sure time turns to "Released" and an anime to "Aired in Japan"; an estimate keeps "Expected"
    /// (`ReleaseVerb.word(past:)`). A weekday, never "today": the view isn't redrawn at midnight, so "tomorrow" would go
    /// stale while the timer kept ticking.
    static func outLine(_ attributes: DropActivityAttributes, dropDate: Date, out: Bool,
                        formatter: DropFormatter) -> String {
        guard out else { return timeLine(attributes, dropDate: dropDate, formatter: formatter) }
        return "\(attributes.verb.word(past: true)) \(formatter.weekdayTime(dropDate))"
    }

    /// "Delayed from 01:00", or "Moved from 03:00" when it came earlier: a changed time in words. Nil when it hasn't
    /// moved.
    static func movedLine(_ state: DropActivityAttributes.ContentState, formatter: DropFormatter) -> String? {
        guard let previous = state.delayedFrom, let time = previousTime(state, formatter: formatter) else { return nil }
        return "\(previous < state.dropDate ? "Delayed" : "Moved") from \(time)"
    }

    /// The show's initial, where there's no poster: its first letter or digit, "S" for Silo; a title with neither
    /// ("💍") shows its first character, and only an empty one a bullet.
    static func monogram(_ attributes: DropActivityAttributes) -> String {
        let name = attributes.showName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let initial = name.first(where: { $0.isLetter || $0.isNumber }) { return String(initial).uppercased() }
        return name.first.map(String.init) ?? "•"
    }

    // MARK: - Private

    private static func provider(_ attributes: DropActivityAttributes) -> String? {
        guard let label = attributes.provider?.trimmingCharacters(in: .whitespaces), !label.isEmpty else { return nil }
        return label
    }

    /// "Silo and 1 more": the title as it's said.
    private static func spokenTitle(_ attributes: DropActivityAttributes) -> String {
        let others = attributes.dropIDs.count - 1
        return others > 0 ? "\(attributes.showName) and \(others) more" : attributes.showName
    }

    /// "in 2 hours", "expected in 2 hours", "airs in Japan in 2 hours", "out now": `ReleaseVerb.spoken`, as the
    /// widgets say it. Unlike a widget in its last day (D-61), the activity speaks a countdown up to the drop.
    private static func when(_ attributes: DropActivityAttributes, state: DropActivityAttributes.ContentState,
                             out: Bool, now: Date) -> String {
        let parts = CountdownFormatter.parts(from: now, to: state.dropDate, maxUnits: 2)
        return attributes.verb.spoken(left: out || parts.isEmpty ? nil : CountdownFormatter.spokenText(parts))
    }
}
