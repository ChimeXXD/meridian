import Foundation

/// What a countdown shows at a given moment (SPEC Upcoming sections; CLAUDE.md rule 4).
enum CountdownState: Hashable, Sendable {
    /// No time announced: show the airdate and never a timer.
    case dateOnly
    /// From the drop until an hour after it.
    case outNow
    /// More than an hour after the drop.
    case released
    /// Within 24 hours: a ticking `Text(timerInterval:countsDown:)` (no `pauseTime`, D-52).
    case ticking
    /// More than 24 hours away: a static "2d 4h".
    case coarse([CountdownPart])
}
