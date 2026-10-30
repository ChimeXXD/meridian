import SwiftUI

/// An Upcoming section title with a small count under it (#1 Brink).
struct SectionHeader: View {
    /// Test ID suffix, e.g. "next-24" gives `section-header-next-24`.
    let id: String
    let title: String
    let count: Int

    static func countText(_ count: Int) -> String {
        switch count {
        case 0: "No shows"
        case 1: "1 show"
        default: "\(count) shows"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.title3.weight(.bold))
            Text(Self.countText(count)).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("section-header-\(id)")
    }
}

#Preview("Section headers") {
    VStack(spacing: Tokens.Space.l) {
        SectionHeader(id: "out-now", title: "Out now", count: 1)
        SectionHeader(id: "next-24", title: "Next 24 hours", count: 3)
    }
    .padding()
}
