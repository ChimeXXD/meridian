import SwiftUI
import UIKit

/// Report and Unfollow as a grouped card, like Settings' rows (Chime and the UX audit #4, 2 Nov: as grey text they
/// looked disabled, and the grey hid Unfollow's red). Report's ↗ says it opens a web page (in a sheet); Unfollow is red and always asks
/// first (UX audit #15). Shared by Show detail and a quiet show's page.
struct ShowActionsCard: View {
    let showName: String
    /// Nil leaves Report out: a quiet show has no time to report.
    var onReport: (() -> Void)?
    let onUnfollow: () -> Void

    /// The rows' symbol column grows with the text, so a large symbol never overlaps its label.
    @ScaledMetric(relativeTo: .body) private var iconColumn: CGFloat = 24
    @State private var confirmingUnfollow = false

    var body: some View {
        VStack(spacing: 0) {
            if let onReport {
                Button(action: onReport) {
                    row("Report a wrong time", systemImage: "exclamationmark.bubble", ink: .white, leavesApp: true)
                }
                .accessibilityIdentifier("detail-report")
                .accessibilityHint(ReportRoute.current == .githubIssue ? "Opens a GitHub issue" : "Opens an email")
                Rectangle().fill(.white.opacity(0.12)).frame(height: 0.5)
                    .padding(.leading, Tokens.Space.m + iconColumn + Tokens.Space.s)
            }
            Button(role: .destructive) { confirmingUnfollow = true } label: {
                row("Unfollow", systemImage: "minus.circle", ink: Color(uiColor: .systemRed), leavesApp: false)
            }
            .accessibilityIdentifier("detail-unfollow")
        }
        .buttonStyle(CardRowPressStyle())
        .background(.white.opacity(0.08), in: .rect(cornerRadius: Tokens.Radius.card))
        .clipShape(.rect(cornerRadius: Tokens.Radius.card))  // keeps a pressed row's fill inside the corners
        .unfollowConfirmation(showName, isPresented: $confirmingUnfollow, onUnfollow: onUnfollow)
    }

    /// One row: a symbol in a fixed column, the label, and an arrow when it opens another app. At least 52 pt tall,
    /// tappable across its width.
    private func row(_ title: String, systemImage: String, ink: Color, leavesApp: Bool) -> some View {
        HStack(spacing: Tokens.Space.s) {
            Image(systemName: systemImage)
                .font(.body)
                .frame(width: iconColumn)
                .accessibilityHidden(true)
            Text(title)
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            if leavesApp {
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(NightInk.muted)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(ink)
        .padding(.horizontal, Tokens.Space.m)
        .frame(minHeight: 52)
        .contentShape(.rect)
    }
}

extension View {
    /// "Stop following Silo?" with a red Unfollow: the one confirmation every unfollow goes through (UX audit #15).
    func unfollowConfirmation(_ showName: String, isPresented: Binding<Bool>, onUnfollow: @escaping () -> Void)
        -> some View {
        confirmationDialog("Stop following \(showName)?", isPresented: isPresented, titleVisibility: .visible) {
            Button("Unfollow", role: .destructive, action: onUnfollow)
        }
    }

    /// The same confirmation for one of many shows (Search's poster grid): it asks while `item` is set, about it.
    func unfollowConfirmation<Item>(_ item: Binding<Item?>, title: KeyPath<Item, String>,
                                    onUnfollow: @escaping (Item) -> Void) -> some View {
        confirmationDialog("Stop following \(item.wrappedValue?[keyPath: title] ?? "")?",
                           isPresented: Binding(get: { item.wrappedValue != nil },
                                                set: { if !$0 { item.wrappedValue = nil } }),
                           titleVisibility: .visible, presenting: item.wrappedValue) { show in
            Button("Unfollow", role: .destructive) { onUnfollow(show) }
        }
    }
}
