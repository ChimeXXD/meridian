import CoreGraphics
import Foundation
import Testing

/// `art-holes.json`, beside the renders in `fidelity/shots/widgets/` and `fidelity/shots/live-activity/`: for every
/// render cut by `ArtMatte`, each hole's rect in the PNG's pixels and how the app fits art into it, so the design
/// system can put the show's real art behind the PNG exactly where the phone draws it.
struct ArtHoleManifest: Codable {
    /// One art region.
    struct Hole: Codable, Equatable {
        /// The art's frame in the PNG's pixels (the render's points × `scale`), before any clip.
        var x: Double, y: Double, w: Double, h: Double
        /// The clip's corner radius in pixels, and its curve: "continuous" (SwiftUI's `.continuous`), "circular", or
        /// "none" with radius 0. A circle has `circle` true.
        var radius: Double
        var corner: String
        var circle: Bool
        /// How the art fills the frame: always "cover" (`scaledToFill`), anchored "top" or "center" as the view
        /// crops it.
        var fit = "cover"
        var align: String
        /// The sample show the art belongs to, by name.
        var show: String
        /// Which of the app's saved images it is (D-46/D-47): "wide" is `ShowArtwork.widget` (the key art, or the
        /// poster when the show only has a banner strip), "poster" is `ShowArtwork.widgetPoster` (2:3).
        var kind: String
    }

    struct Shot: Codable, Equatable {
        var width: Int
        var height: Int
        var holes: [Hole]
    }

    var about = "Art holes for the design system: in each PNG the show's art is cut out (alpha 0) and the fades over "
        + "it are kept as translucent pixels. Rects are in the PNG's pixels; place the art behind at each rect, "
        + "object-fit: cover with the given anchor."
    var scale: Double = 3
    var shots: [String: Shot] = [:]

    /// Adds or replaces one render's entry in the folder's manifest. Tests run one at a time on the main actor, so the
    /// read, merge and write never interleave.
    @MainActor
    static func record(_ shot: Shot, name: String, in folder: URL) throws {
        let url = folder.appendingPathComponent("art-holes.json")
        var manifest = (try? JSONDecoder().decode(Self.self, from: Data(contentsOf: url))) ?? Self()
        manifest.shots[name] = shot
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(manifest).write(to: url, options: .atomic)
    }
}

/// What a render's art is expected to be, so its holes come from the real layout and are checked against the alpha.
enum ArtHoleExpectation {
    /// A full frame known from the layout, as a share of the render (the widget hero's top `coverage`, the Lock
    /// Screen's right edge). Its fade means the alpha alone can't show where it ends.
    case frame(unit: CGRect, align: String, show: String, kind: String)
    /// A clipped image of a known size in points, found where the render is clear (posters, island art). Patches are
    /// matched to these top to bottom.
    case patch(size: CGSize, radius: CGFloat, circle: Bool, show: String, kind: String)
}

extension ArtMatte {
    /// The manifest entry for this matte, from what the layout says the art is. Records an issue when a hole isn't
    /// where the layout puts it, isn't fully clear, or the render lets anything through outside the holes.
    func shot(_ expected: [ArtHoleExpectation], scale: CGFloat, name: String) -> ArtHoleManifest.Shot {
        #expect(linearityError <= 3, "\(name): the art doesn't composite linearly (off by \(linearityError))")
        var holes: [ArtHoleManifest.Hole] = []
        var frames: [CGRect] = []
        let canvas = CGRect(x: 0, y: 0, width: width, height: height)
        for case let .frame(unit, align, show, kind) in expected {
            let rect = CGRect(x: unit.minX * canvas.width, y: unit.minY * canvas.height,
                              width: unit.width * canvas.width, height: unit.height * canvas.height)
            frames.append(rect)
            holes.append(.init(x: rect.minX, y: rect.minY, w: rect.width, h: rect.height, radius: 0, corner: "none",
                               circle: false, align: align, show: show, kind: kind))
        }
        let wanted = expected.compactMap { item -> (CGSize, CGFloat, Bool, String, String)? in
            guard case let .patch(size, radius, circle, show, kind) = item else { return nil }
            return (CGSize(width: size.width * scale, height: size.height * scale), radius * scale, circle, show, kind)
        }
        // A clear patch inside a full frame that isn't a poster's size is part of that frame's art: its clear top, or
        // the gaps between a tag's letters over it.
        let fits = { (patch: CGRect) in
            wanted.contains { abs(patch.width - $0.0.width) <= 2 && abs(patch.height - $0.0.height) <= 2 }
        }
        let patches = clearPatches().filter { patch in
            fits(patch) || !frames.contains { $0.insetBy(dx: -1, dy: -1).contains(patch) }
        }
        #expect(patches.count == wanted.count,
                "\(name): \(patches.count) clear patches \(patches) for \(wanted.count) expected")
        for (patch, want) in zip(patches, wanted) {
            #expect(abs(patch.width - want.0.width) <= 2 && abs(patch.height - want.0.height) <= 2,
                    "\(name): a \(want.3) patch is \(patch.size), expected \(want.0)")
            // The view's frame, centred on the patch: anti-aliasing can leave the edge rows half clear.
            let rect = CGRect(x: patch.midX - want.0.width / 2, y: patch.midY - want.0.height / 2,
                              width: want.0.width, height: want.0.height)
            frames.append(rect)
            holes.append(.init(x: rect.minX, y: rect.minY, w: rect.width, h: rect.height,
                               radius: want.2 ? want.0.width / 2 : want.1, corner: want.2 ? "circular" : "continuous",
                               circle: want.2, align: "center", show: want.3, kind: want.4))
        }
        for rect in frames {
            #expect(minimumAlpha(in: rect) == 0, "\(name): the hole at \(rect) is never fully clear")
        }
        let stray = strayPixels(outside: frames)
        #expect(stray == 0, "\(name): \(stray) see-through pixels outside the holes")
        return .init(width: width, height: height, holes: holes.map(\.rounded))
    }
}

private extension ArtHoleManifest.Hole {
    /// Two decimals: the rects are thirds of a pixel at most, and the JSON stays readable.
    var rounded: Self {
        let r = { (value: Double) in (value * 100).rounded() / 100 }
        var copy = self
        (copy.x, copy.y, copy.w, copy.h, copy.radius) = (r(x), r(y), r(w), r(h), r(radius))
        return copy
    }
}
