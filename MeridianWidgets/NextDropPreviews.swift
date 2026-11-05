import SwiftUI
import WidgetKit

// Every family in every state UI-BRIEF §6.1 lists, and the worst cases, from `WidgetSamples` (no artwork, CLAUDE.md
// rule 9). Step through the entries in the canvas; switch the canvas to tinted or Always-On to check those modes.

private let now = Date.now
private let all = WidgetSamples.Case.allCases.map { WidgetSamples.moment($0, now: now) }

#Preview("Inline", as: .accessoryInline) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]; all[6]; all[7]; all[8]
}

#Preview("Circular", as: .accessoryCircular) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]; all[6]; all[7]; all[8]
}

#Preview("Rectangular", as: .accessoryRectangular) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]; all[6]; all[7]; all[8]
}

#Preview("Small", as: .systemSmall) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]; all[6]; all[7]; all[8]
}

#Preview("Medium", as: .systemMedium) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]; all[6]; all[7]; all[8]
}

#Preview("Large", as: .systemLarge) {
    NextDropWidget()
} timeline: {
    all[0]; all[1]; all[2]; all[3]; all[4]; all[5]; all[6]; all[7]; all[8]
}

// The worst cases the layouts must survive (break-ui, 5 Nov): a 60-character name on "Paramount+ with Showtime · US",
// Japanese and Arabic names, a drop over a year away, a long name just out. Set the canvas to the largest text size
// too: the widgets' countdowns don't grow with it.
private let worst = WidgetSamples.WorstCase.allCases.map { WidgetSamples.moment($0, now: now) }

#Preview("Inline, worst cases", as: .accessoryInline) {
    NextDropWidget()
} timeline: {
    worst[0]; worst[1]; worst[2]; worst[3]
}

#Preview("Rectangular, worst cases", as: .accessoryRectangular) {
    NextDropWidget()
} timeline: {
    worst[0]; worst[1]; worst[2]; worst[3]
}

#Preview("Small, worst cases", as: .systemSmall) {
    NextDropWidget()
} timeline: {
    worst[0]; worst[1]; worst[2]; worst[3]
}

#Preview("Medium, worst cases", as: .systemMedium) {
    NextDropWidget()
} timeline: {
    worst[0]; worst[1]; worst[2]; worst[3]
}

#Preview("Large, worst cases", as: .systemLarge) {
    NextDropWidget()
} timeline: {
    worst[0]; worst[1]; worst[2]; worst[3]
}
