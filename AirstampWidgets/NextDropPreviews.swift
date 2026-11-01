import SwiftUI
import WidgetKit

// Every family in every state UI-BRIEF §6.1 lists, from `WidgetSamples` (no artwork, CLAUDE.md rule 9). Step through
// the entries in the canvas; switch the canvas to tinted or Always-On to check those modes.

private let now = Date.now
private let all = WidgetSamples.Case.allCases.map { WidgetSamples.moment($0, now: now) }

#Preview("Inline", as: .accessoryInline) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]
}

#Preview("Circular", as: .accessoryCircular) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]
}

#Preview("Rectangular", as: .accessoryRectangular) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]
}

#Preview("Small", as: .systemSmall) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]
}

#Preview("Medium", as: .systemMedium) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]
}
