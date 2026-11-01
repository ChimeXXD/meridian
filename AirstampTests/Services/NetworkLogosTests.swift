import Foundation
import Testing
@testable import Airstamp

/// Service logos for Search's filter chips (D-44): a hand-checked list of freely licensed Wikimedia Commons files,
/// loaded at runtime like posters, never committed as image files (rule 9).
@Suite("Network logos")
struct NetworkLogosTests {
    static func sample() throws -> NetworkLogos {
        try JSONDecoder().decode(NetworkLogos.self, from: Fixture.data("logos/network-logos-sample.json"))
    }

    @Test("a service's logo is found by its exact TVmaze name, one file for several names")
    func lookup() throws {
        let logos = try Self.sample()
        #expect(logos.image(for: "NBC")?.absoluteString.hasSuffix("120px-NBC_logo.svg.png") == true)
        #expect(logos.image(for: "HBO") == logos.image(for: "HBO Max"))
        #expect(logos.image(for: "CBS") == nil)
        #expect(logos.image(for: "nbc") == nil)
    }

    @Test("files that ask for credit are listed for the Credits screen")
    func credits() throws {
        #expect(try Self.sample().credits == ["HBO logo: Example Author, CC BY-SA 4.0, via Wikimedia Commons"])
    }

    @Test("the bundled list credits the three files whose licence asks for it")
    func bundledCredits() {
        #expect(NetworkLogos.loadBundled().credits.count == 3)
        #expect(NetworkLogos.loadBundled().credits.contains("AMC+ logo: Ardi3005, CC BY-SA 4.0, via Wikimedia Commons"))
    }

    @Test("the bundled list is valid: Commons images over https, a license each, no name twice")
    func bundled() throws {
        let logos = NetworkLogos.loadBundled()
        #expect(!logos.logos.isEmpty)
        // Commons serves thumbnails from thumb.wikimedia.org (its API's answer, 1 Nov 2026), originals from upload.
        #expect(logos.logos.allSatisfy { $0.image.scheme == "https" && ($0.image.host ?? "").hasSuffix(".wikimedia.org") })
        #expect(logos.logos.allSatisfy { !$0.license.isEmpty && !$0.names.isEmpty })
        let names = logos.logos.flatMap(\.names)
        #expect(Set(names).count == names.count)
    }
}
