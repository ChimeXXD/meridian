import SwiftUI
import UIKit

/// The status family a source chip belongs to. It sets the chip's ink and glyph (UI-BRIEF §2).
enum SourceKind: CaseIterable, Sendable {
    case exact, estimated, adjusted, dateOnly

    var ink: UIColor {
        switch self {
        case .exact: Tokens.Ink.exact
        case .estimated: Tokens.Ink.estimated
        case .adjusted: Tokens.Ink.adjusted
        case .dateOnly: Tokens.Ink.dateOnly
        }
    }

    /// SF Symbol name, so the chip never relies on colour alone.
    var glyph: String {
        switch self {
        case .exact: "checkmark.circle.fill"
        case .estimated: "clock"
        case .adjusted: "slider.horizontal.3"
        case .dateOnly: "calendar"
        }
    }
}
