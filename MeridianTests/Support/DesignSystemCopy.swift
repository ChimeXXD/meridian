import Foundation
import Testing

/// The design system's widget and Live Activity pictures are copies of these renders (`design-system/assets/widgets/`
/// and `design-system/assets/live-activity/`). Every render checks its copy, so the site can't drift from the app:
/// change a view, look at its new render, then run `scripts/sync-design-system-renders.sh` to update the site in the
/// same commit (Chime, 2 Nov: "changes to the design system go to the app, and vice versa").
enum DesignSystemCopy {
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()

    /// Expects the site's copy of `name` in `folder` to be this exact PNG. A missing copy fails too, so a new state
    /// reaches the site.
    static func expectMatches(_ png: Data, name: String, folder: String,
                              sourceLocation: SourceLocation = #_sourceLocation) {
        // Set by the sync script, so every other check must still pass before it copies anything, and by CI, whose
        // older iOS draws text a little differently (the local gate checks the copies on iOS 27).
        if ProcessInfo.processInfo.environment["MERIDIAN_SYNC_RENDERS"] == "1" { return }
        let path = "design-system/assets/\(folder)/\(name)"
        let copy = try? Data(contentsOf: root.appendingPathComponent(path))
        #expect(copy == png, "\(path) isn't the app's render: run scripts/sync-design-system-renders.sh",
                sourceLocation: sourceLocation)
    }
}
