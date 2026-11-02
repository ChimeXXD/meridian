import SwiftUI
import Testing
import UIKit
@testable import Meridian

/// D4-3, D4-4: renders every widget family in every state with `ImageRenderer` into `fidelity/shots/widgets/`
/// (git-ignored) for Chime to look at, and checks each one fits its family's height, so no line is pushed out.
/// `ImageRenderer` can't set `widgetRenderingMode`, so tinted and accented are seen in the previews; Always-On is
/// rendered here through `isLuminanceReduced`. The renders with art are cut by `ArtMatte`: the art is a hole, listed in
/// `art-holes.json`, which the design system fills with the show's real art at runtime.
@MainActor
@Suite("Widget renders")
struct WidgetRenderTests {
    enum Family: String, CaseIterable {
        case inline, circular, rectangular, small, medium, large

        /// The smallest current iPhone Pro sizes, in points, so anything that fits here fits everywhere.
        var size: CGSize {
            switch self {
            case .inline: CGSize(width: 234, height: 22)
            case .circular: CGSize(width: 72, height: 72)
            case .rectangular: CGSize(width: 160, height: 72)
            case .small: CGSize(width: 158, height: 158)
            case .medium: CGSize(width: 338, height: 158)
            case .large: CGSize(width: 338, height: 354)
            }
        }

        /// The system widgets get the default 16 pt content margins; Lock Screen ones have none.
        var margin: CGFloat { [.small, .medium, .large].contains(self) ? 16 : 0 }
        /// The content's size inside the margins.
        var inner: CGSize { CGSize(width: size.width - 2 * margin, height: size.height - 2 * margin) }
    }

    static let now = Date(iso: "2026-11-02T18:00:00Z")
    static let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()

    static var folder: URL { root.appendingPathComponent("fidelity/shots/widgets", isDirectory: true) }

    @ViewBuilder static func view(_ family: Family, _ moment: WidgetMoment, art: UIImage? = nil,
                                  posters: [String: UIImage] = [:]) -> some View {
        switch family {
        case .inline: InlineWidgetView(moment: moment, formatter: formatter)
        case .circular: CircularWidgetView(moment: moment, formatter: formatter)
        case .rectangular: RectangularWidgetView(moment: moment, formatter: formatter)
        case .small: SmallWidgetView(moment: moment, art: art, formatter: formatter)
        case .medium: MediumWidgetView(moment: moment, heroArt: art, posters: posters, formatter: formatter)
        case .large: LargeWidgetView(moment: moment, heroArt: art, posters: posters, formatter: formatter)
        }
    }

    /// The same poster for every row's show, as the App Group holds one per followed show.
    static func posters(_ moment: WidgetMoment, _ poster: UIImage?) -> [String: UIImage] {
        guard let poster else { return [:] }
        let ids = moment.upNext.map(\.showID) + moment.nothingScheduled.map(\.showID)
        return Dictionary(ids.map { ($0, poster) }, uniquingKeysWith: { first, _ in first })
    }

    /// The show whose art the widget's backdrop draws, as `NextDropWidget` picks it: the small widget's current drop,
    /// the others' first upcoming one. None means no hero art, whatever the App Group holds.
    static func hero(_ family: Family, _ moment: WidgetMoment) -> Drop? {
        switch family {
        case .small: moment.current
        case .medium, .large: moment.upNext.first
        case .inline, .circular, .rectangular: nil
        }
    }

    /// What the system draws behind each family. `containerBackground` does nothing outside a widget.
    @ViewBuilder static func backdrop(_ family: Family, art: UIImage?) -> some View {
        switch family {
        case .small, .medium: WidgetBackdrop(art: art)
        case .large: WidgetBackdrop(art: art, coverage: LargeWidgetView.artCoverage)
        case .inline, .circular, .rectangular: Color.black
        }
    }

    /// The family at its size, at 3x, over its backdrop: the art (if any) behind the hero, the poster beside each row.
    static func image(_ family: Family, _ moment: WidgetMoment, art: UIImage?, poster: UIImage?,
                      dimmed: Bool) throws -> UIImage {
        let inner = family.inner
        let heroArt = hero(family, moment) == nil ? nil : art
        let shot = ImageRenderer(content: view(family, moment, art: heroArt, posters: posters(moment, poster))
            .frame(width: inner.width, height: inner.height)
            .padding(family.margin)
            .background(backdrop(family, art: heroArt))
            .environment(\.colorScheme, .dark)
            .environment(\.isLuminanceReduced, dimmed))
        shot.scale = 3
        return try #require(shot.uiImage)
    }

    /// Renders one state into the shots folder and returns how much more height it needs than its family has. With
    /// `withArt`, the PNG is cut by `ArtMatte` (the hero's art and the rows' posters are holes, listed in
    /// `art-holes.json`), so the design system can show each show's real art behind it.
    static func render(_ family: Family, _ sample: WidgetSamples.Case, withArt: Bool = false, dimmed: Bool = false,
                       name: String) throws -> CGFloat {
        let moment = WidgetSamples.moment(sample, now: now)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let png: Data
        if withArt {
            let matte = try ArtMatte.cut { fill in try image(family, moment, art: fill, poster: fill, dimmed: dimmed) }
            #expect(CGSize(width: matte.width, height: matte.height) == CGSize(width: family.size.width * 3,
                                                                               height: family.size.height * 3))
            try ArtHoleManifest.record(matte.shot(holes(family, moment, dimmed: dimmed), scale: 3, name: name),
                                       name: "\(name).png", in: folder)
            png = try matte.png
        } else {
            let plain = try image(family, moment, art: nil, poster: nil, dimmed: dimmed)
            #expect(plain.size == family.size, "\(name) rendered at \(plain.size)")
            png = try #require(plain.pngData())
        }
        try png.write(to: folder.appendingPathComponent("\(name).png"))

        // The height the content needs at the family's width, with nothing squeezed (the rows' posters take width).
        let natural = ImageRenderer(content: view(family, moment, posters: posters(moment, withArt ? poster : nil))
            .frame(width: family.inner.width)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.isLuminanceReduced, dimmed))
        return try #require(natural.uiImage).size.height - family.inner.height
    }

    /// Where the art goes, from the layout: the hero's key art across the top `coverage` of the widget, anchored top
    /// (`WidgetBackdrop`), then each row's 2:3 poster (`WidgetPosterThumb`), top to bottom in the views' row order.
    static func holes(_ family: Family, _ moment: WidgetMoment, dimmed: Bool) -> [ArtHoleExpectation] {
        guard !dimmed else { return [] }
        var holes: [ArtHoleExpectation] = []
        if let heroDrop = hero(family, moment) {
            let coverage = family == .large ? LargeWidgetView.artCoverage : 1
            holes.append(.frame(unit: CGRect(x: 0, y: 0, width: 1, height: coverage), align: "top",
                                show: heroDrop.showName, kind: "wide"))
        }
        let (shown, height): (Int, CGFloat) = switch family {
        case .medium: (MediumWidgetView.shown, WidgetCompactRow.posterHeight)
        case .large: (LargeWidgetView.shown, MediumWidgetRow.thumbnail)
        default: (0, 0)
        }
        guard shown > 0 else { return holes }
        let names = moment.rows(showing: shown).map(\.showName) + moment.quietRows(showing: shown).map(\.name)
        for name in names {
            holes.append(.patch(size: CGSize(width: height * 2 / 3, height: height), radius: height / 6, circle: false,
                                show: name, kind: "poster"))
        }
        return holes
    }

    /// A neutral 2:3 poster, never real artwork (CLAUDE.md rule 9), for the natural-height check.
    static let poster = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30)).image { context in
        UIColor(white: 0.7, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: 0, width: 20, height: 30))
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

    @Test("the Home Screen widgets read the same over art, and their art cuts out cleanly",
          arguments: [Family.small, .medium, .large])
    func withArt(family: Family) throws {
        for sample in [WidgetSamples.Case.countdown, .ticking, .busy, .quiet, .allQuiet] {
            let name = "\(family.rawValue)-\(sample.rawValue)-art"
            let overflow = try Self.render(family, sample, withArt: true, name: name)
            #expect(overflow <= 0.5, "\(name) needs \(overflow) pt more height")
        }
    }

    @Test("no widget view uses a counting-up text style (CLAUDE.md rule 4)")
    func noTimerStyle() throws {
        let folders = ["MeridianWidgets", "Shared/Widgets"].map { Self.root.appendingPathComponent($0) }
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
