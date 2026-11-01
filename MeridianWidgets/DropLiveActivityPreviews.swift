import SwiftUI
import WidgetKit

// The Live Activity in every presentation and every state UI-BRIEF §6.2 lists, from `LiveActivitySamples`, with
// whatever art the App Group holds for their show IDs (none is committed, CLAUDE.md rule 9). Step through the content
// states in the canvas. "Out now" is shown here through the `.outNow` phase; a stale context draws the same view.

private let now = Date.now

#Preview("Lock Screen", as: .content, using: LiveActivitySamples.attributes(.countingDown)) {
    DropLiveActivity()
} contentStates: {
    LiveActivitySamples.state(.countingDown, now: now)
    LiveActivitySamples.state(.delayed, now: now)
    LiveActivitySamples.state(.outNow, now: now)
}

#Preview("Lock Screen, long name", as: .content, using: LiveActivitySamples.attributes(.longName)) {
    DropLiveActivity()
} contentStates: {
    LiveActivitySamples.state(.longName, now: now)
    LiveActivitySamples.state(.outNow, now: now)
}

#Preview("Lock Screen, merged", as: .content, using: LiveActivitySamples.attributes(.merged)) {
    DropLiveActivity()
} contentStates: {
    LiveActivitySamples.state(.merged, now: now)
}

#Preview("Compact", as: .dynamicIsland(.compact), using: LiveActivitySamples.attributes(.countingDown)) {
    DropLiveActivity()
} contentStates: {
    LiveActivitySamples.state(.countingDown, now: now)
    LiveActivitySamples.state(.outNow, now: now)
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: LiveActivitySamples.attributes(.countingDown)) {
    DropLiveActivity()
} contentStates: {
    LiveActivitySamples.state(.countingDown, now: now)
    LiveActivitySamples.state(.outNow, now: now)
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: LiveActivitySamples.attributes(.longName)) {
    DropLiveActivity()
} contentStates: {
    LiveActivitySamples.state(.longName, now: now)
    LiveActivitySamples.state(.outNow, now: now)
}

#Preview("Expanded, delayed", as: .dynamicIsland(.expanded), using: LiveActivitySamples.attributes(.delayed)) {
    DropLiveActivity()
} contentStates: {
    LiveActivitySamples.state(.delayed, now: now)
}
