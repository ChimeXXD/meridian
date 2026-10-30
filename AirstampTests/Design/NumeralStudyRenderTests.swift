import SwiftUI
import Testing
@testable import Airstamp

/// Renders each numeral study to PNG for Chime to compare. Off in normal runs; enable it with
/// `TEST_RUNNER_STUDIES_OUT=$PWD/docs/design/studies xcodebuild … test -only-testing:AirstampTests/NumeralStudyRenderTests`.
@MainActor
@Suite("Numeral study renders", .enabled(if: ProcessInfo.processInfo.environment["STUDIES_OUT"] != nil))
struct NumeralStudyRenderTests {
    @Test("render every study in dark and light", arguments: NumeralStudy.allCases)
    func render(study: NumeralStudy) throws {
        let folder = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["STUDIES_OUT"]))
        let now = Date.now
        for scheme in [ColorScheme.dark, .light] {
            let renderer = ImageRenderer(content: NumeralStudyBoard(study: study, now: now).environment(\.colorScheme, scheme))
            renderer.scale = 2
            let png = try #require(renderer.uiImage?.pngData())
            try png.write(to: folder.appendingPathComponent("\(study.rawValue)-\(scheme == .dark ? "dark" : "light").png"))
        }
    }
}
