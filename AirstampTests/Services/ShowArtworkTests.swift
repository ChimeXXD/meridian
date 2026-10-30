import Foundation
import Testing
@testable import Airstamp

/// Artwork comes from TVmaze at runtime (D-37). The fixture lists image URLs only; no image is stored.
@Suite("Show artwork")
struct ShowArtworkTests {
    @Test("images(showID:) asks TVmaze for the show's images and parses them")
    func fetchesImages() async throws {
        let network = TVmazeClientTests.FakeNetwork([try TVmazeClientTests.ok("images-silo")])
        let images = try await TVmazeClientTests.client(network).images(showID: 38052)
        #expect(images.count == 18)
        let url = try #require(await network.requests.first)
        #expect(url.absoluteString == "https://api.tvmaze.com/shows/38052/images")
    }

    @Test("picks a background near 1920 px wide (not the 3840 px original) and the main poster")
    func picksSensibleSizes() throws {
        let images = try JSONDecoder().decode([TVmazeImage].self, from: Fixture.data("tvmaze/images-silo.json"))
        let artwork = ShowArtwork(images: images)
        #expect(artwork.background?.absoluteString.hasSuffix("/460/1151687.jpg") == true)
        #expect(artwork.poster?.absoluteString.hasSuffix("/631/1577677.jpg") == true)
        #expect(artwork.posterThumbnail?.absoluteString.contains("/medium_portrait/") == true)
    }

    @Test("a show without a background falls back to its poster for the hero")
    func posterFallback() throws {
        let poster = TVmazeImage(type: "poster", main: true, resolutions: [
            "original": .init(url: URL(string: "https://static.tvmaze.com/p.jpg")!, width: 680, height: 1000),
        ])
        let artwork = ShowArtwork(images: [poster])
        #expect(artwork.background == nil)
        #expect(artwork.hero == URL(string: "https://static.tvmaze.com/p.jpg"))
    }

    @Test("a sharp background beats a soft one even when TVmaze marks the soft one main")
    func sharpBeatsSoftMain() {
        func background(_ path: String, width: Int, main: Bool) -> TVmazeImage {
            TVmazeImage(type: "background", main: main, resolutions: [
                "original": .init(url: URL(string: "https://static.tvmaze.com/\(path).jpg")!, width: width, height: width * 9 / 16),
            ])
        }
        let artwork = ShowArtwork(images: [background("soft", width: 640, main: true), background("sharp", width: 1920, main: false)])
        #expect(artwork.background == URL(string: "https://static.tvmaze.com/sharp.jpg"))
    }
}
