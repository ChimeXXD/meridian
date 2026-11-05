import SwiftUI
import Testing
import UIKit
import Vision
@testable import Meridian

/// The worst cases break-ui found (5 Nov): a 60-character name, "Paramount+ with Showtime · US", Japanese and Arabic
/// names, a drop over a year away, and the largest text size. Rendered into `fidelity/shots/worst-cases/` (git-ignored)
/// to look at, never copied to the design system, which shows the real states only.
extension WidgetRenderTests {
    static var worstFolder: URL { root.appendingPathComponent("fidelity/shots/worst-cases", isDirectory: true) }

    /// Every sample, the real states and the worst cases, by name.
    static var everyMoment: [(name: String, moment: WidgetMoment)] {
        WidgetSamples.Case.allCases.map { ($0.rawValue, WidgetSamples.moment($0, now: now)) }
            + WidgetSamples.WorstCase.allCases.map { ($0.rawValue, WidgetSamples.moment($0, now: now)) }
    }

    /// The family at its size over its plain backdrop, at 3x, saved into the worst-case folder.
    static func worstShot(_ family: Family, _ moment: WidgetMoment, name: String,
                          size: DynamicTypeSize = .large) throws -> UIImage {
        let shot = ImageRenderer(content: view(family, moment)
            .frame(width: family.inner.width, height: family.inner.height)
            .padding(family.margin)
            .background(backdrop(family, art: nil))
            .environment(\.colorScheme, .dark)
            .environment(\.dynamicTypeSize, size))
        shot.scale = 3
        let image = try #require(shot.uiImage)
        try FileManager.default.createDirectory(at: worstFolder, withIntermediateDirectories: true)
        try #require(image.pngData()).write(to: worstFolder.appendingPathComponent("\(name).png"))
        return image
    }

    /// How much more height the content needs than its family has, at its width with nothing squeezed.
    static func overflow(_ family: Family, _ moment: WidgetMoment, size: DynamicTypeSize) throws -> CGFloat {
        let natural = ImageRenderer(content: view(family, moment)
            .frame(width: family.inner.width)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.dynamicTypeSize, size))
        return try #require(natural.uiImage).size.height - family.inner.height
    }

    /// The words Vision reads in a render, one line each.
    static func words(in image: UIImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: try #require(image.cgImage)).perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }

    @Test("a long provider keeps its country where a widget tags it (D-20, CLAUDE.md rule 11)",
          arguments: [Family.small, .rectangular])
    func providerKeepsCountry(family: Family) throws {
        let image = try Self.worstShot(family, WidgetSamples.moment(.longNames, now: Self.now),
                                       name: "\(family.rawValue)-longNames")
        let text = try Self.words(in: image)
        // Vision reads small capitals as it likes ("us"), so the provider's line is matched without case.
        let provider = text.lowercased().split(separator: "\n").first { $0.contains("paramount") }
        #expect(provider?.hasSuffix("us") == true, "\(family.rawValue) reads: \(text)")
    }

    /// The inline widget is left out: the system draws it in its own font, so its render at the largest size isn't
    /// what the phone shows.
    @Test("every family fits its height in every sample and worst case, at the default and the largest text size",
          arguments: Family.allCases.filter { $0 != .inline })
    func worstCasesFit(family: Family) throws {
        for (name, moment) in Self.everyMoment {
            for size in [DynamicTypeSize.large, .accessibility5] {
                let overflow = try Self.overflow(family, moment, size: size)
                #expect(overflow <= 0.5, "\(family.rawValue)-\(name) at \(size) needs \(overflow) pt more height")
            }
        }
        for worst in WidgetSamples.WorstCase.allCases {
            let moment = WidgetSamples.moment(worst, now: Self.now)
            _ = try Self.worstShot(family, moment, name: "\(family.rawValue)-\(worst.rawValue)")
            _ = try Self.worstShot(family, moment, name: "\(family.rawValue)-\(worst.rawValue)-ax5",
                                   size: .accessibility5)
        }
    }

    @Test("the inline worst cases render, to look at")
    func inlineWorstCases() throws {
        for worst in WidgetSamples.WorstCase.allCases {
            _ = try Self.worstShot(.inline, WidgetSamples.moment(worst, now: Self.now), name: "inline-\(worst.rawValue)")
        }
    }
}
