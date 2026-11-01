import SwiftUI

/// The show's initial in serif inside a thin ring: the Dynamic Island's compact leading mark ("S" for Silo).
struct LiveActivityMonogram: View {
    let attributes: DropActivityAttributes
    var diameter: CGFloat = 24

    var body: some View {
        Text(LiveActivityText.monogram(attributes))
            .font(.system(size: diameter * 0.58, weight: .semibold, design: .serif))
            .foregroundStyle(LiveActivityInk.primary)
            .frame(width: diameter, height: diameter)
            .overlay(Circle().strokeBorder(LiveActivityInk.muted, lineWidth: 1))
    }
}
