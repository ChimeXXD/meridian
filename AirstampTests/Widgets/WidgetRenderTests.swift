import SwiftUI
import Testing
import UIKit
@testable import Airstamp

/// D4-3, D4-4: renders every widget family in every state with `ImageRenderer` into `fidelity/shots/widgets/`
/// (git-ignored) for Chime to look at, and checks each one fits its family's height, so no line is pushed out.
/// `ImageRenderer` can't set `widgetRenderingMode`, so tinted and accented are seen in the previews; Always-On is
/// rendered here through `isLuminanceReduced`.
@MainActor
@Suite("Widget renders")
struct WidgetRenderTests {
    enum Family: String, CaseIterable {
        case inline, circular, rectangular, small, medium

        /// The smallest current iPhone Pro sizes, in points, so anything that fits here fits everywhere.
        var size: CGSize {
            switch self {
            case .inline: CGSize(width: 234, height: 22)
            case .circular: CGSize(width: 72, height: 72)
            case .rectangular: CGSize(width: 160, height: 72)
            case .small: CGSize(width: 158, height: 158)
            case .medium: CGSize(width: 338, height: 158)
            }
        }

        /// The system widgets get the default 16 pt content margins; Lock Screen ones have none.
        var margin: CGFloat { self == .small || self == .medium ? 16 : 0 }
    }

    static let now = Date(iso: "2026-11-02T18:00:00Z")
    static let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()

    @ViewBuilder static func view(_ family: Family, _ moment: WidgetMoment, art: UIImage? = nil) -> some View {
        switch family {
        case .inline: InlineWidgetView(moment: moment, formatter: formatter)
        case .circular: CircularWidgetView(moment: moment, formatter: formatter)
        case .rectangular: RectangularWidgetView(moment: moment, formatter: formatter)
        case .small: SmallWidgetView(moment: moment, art: art, formatter: formatter)
        case .medium:
            MediumWidgetView(moment: moment, art: art.map { image in
                Dictionary(moment.upNext.map { ($0.showID, image) }, uniquingKeysWith: { first, _ in first })
            } ?? [:], formatter: formatter)
        }
    }

    /// What the system draws behind each family. `containerBackground` does nothing outside a widget.
    @ViewBuilder static func backdrop(_ family: Family, art: UIImage?) -> some View {
        switch family {
        case .small: WidgetBackdrop(art: art)
        case .medium: WidgetInk.base
        case .inline, .circular, .rectangular: Color.black
        }
    }

    static func render(_ family: Family, _ sample: WidgetSamples.Case, art: UIImage? = nil, dimmed: Bool = false,
                       name: String) throws -> CGFloat {
        let moment = WidgetSamples.moment(sample, now: now)
        let inner = CGSize(width: family.size.width - 2 * family.margin, height: family.size.height - 2 * family.margin)

        let shot = ImageRenderer(content: view(family, moment, art: art)
            .frame(width: inner.width, height: inner.height)
            .padding(family.margin)
            .background(backdrop(family, art: art))
            .environment(\.colorScheme, .dark)
            .environment(\.isLuminanceReduced, dimmed))
        shot.scale = 3
        let image = try #require(shot.uiImage)
        #expect(image.size == family.size, "\(name) rendered at \(image.size)")
        let folder = root.appendingPathComponent("fidelity/shots/widgets", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try #require(image.pngData()).write(to: folder.appendingPathComponent("\(name).png"))

        // The height the content needs at the family's width, with nothing squeezed.
        let natural = ImageRenderer(content: view(family, moment, art: art)
            .frame(width: inner.width)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.isLuminanceReduced, dimmed))
        return try #require(natural.uiImage).size.height - inner.height
    }

    @Test("every family in every state renders at its size and fits its height", arguments: Family.allCases)
    func renders(family: Family) throws {
        for sample in WidgetSamples.Case.allCases {
            let overflow = try Self.render(family, sample, name: "\(family.rawValue)-\(sample.rawValue)")
            #expect(overflow <= 0.5, "\(family.rawValue)-\(sample.rawValue) needs \(overflow) pt more height")
        }
        let dimmed = try Self.render(family, .ticking, dimmed: true, name: "\(family.rawValue)-ticking-always-on")
        #expect(dimmed <= 0.5)
    }

    @Test("the Home Screen widgets read the same over art", arguments: [Family.small, .medium])
    func withArt(family: Family) throws {
        // A neutral placeholder, never real artwork (CLAUDE.md rule 9).
        let art = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120)).image { context in
            UIColor(white: 0.55, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
            UIColor(white: 0.8, alpha: 1).setFill()
            context.fill(CGRect(x: 20, y: 20, width: 80, height: 50))
        }
        for sample in [WidgetSamples.Case.countdown, .ticking] {
            let overflow = try Self.render(family, sample, art: art, name: "\(family.rawValue)-\(sample.rawValue)-art")
            #expect(overflow <= 0.5)
        }
    }

    @Test("no widget view uses a counting-up text style (CLAUDE.md rule 4)")
    func noTimerStyle() throws {
        let folders = ["AirstampWidgets", "Shared/Widgets"].map { Self.root.appendingPathComponent($0) }
        var files = try folders.flatMap { folder in
            try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "swift" }
        }
        files.append(Self.root.appendingPathComponent("Shared/Design/CountdownText.swift"))
        #expect(files.count > 5)
        let banned = try Regex(#"style:\s*\.(timer|relative)\b|\.timer\b"#)
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            #expect(source.firstMatch(of: banned) == nil, "\(file.lastPathComponent) uses a counting-up text style")
        }
    }
}
