import Foundation
import Testing
@testable import Meridian

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

    @Test("widgets use the wide key art, but an anime's cover rather than AniList's thin banner strip (D-46)")
    func widgetArt() throws {
        let url = { (name: String) in URL(string: "https://example.com/\(name).jpg")! }
        #expect(ShowArtwork(background: url("bg"), poster: url("p"), posterThumbnail: url("t")).widget == url("bg"))
        #expect(ShowArtwork(poster: url("p"), posterThumbnail: url("t")).widget == url("p"))
        #expect(ShowArtwork(posterThumbnail: url("t")).widget == url("t"))
        let json = #"{"id":5,"isAdult":false,"title":{"romaji":"A"},"countryOfOrigin":"JP","bannerImage":"https://example.com/banner.jpg","coverImage":{"large":"https://example.com/cover.jpg","extraLarge":"https://example.com/cover-xl.jpg"}}"#
        let media = try JSONDecoder().decode(AniListMedia.self, from: Data(json.utf8))
        let anime = ShowArtwork(media: media)
        #expect(anime.background == url("banner"), "heroes in the app still use the banner")
        #expect(anime.widget == url("cover-xl"))
    }

    @Test("a widget row's small poster is the poster thumbnail, else the full poster (never the wide art)")
    func widgetPoster() {
        let url = { (name: String) in URL(string: "https://example.com/\(name).jpg")! }
        #expect(ShowArtwork(background: url("bg"), poster: url("p"), posterThumbnail: url("t")).widgetPoster == url("t"))
        #expect(ShowArtwork(background: url("bg"), poster: url("p")).widgetPoster == url("p"))
        #expect(ShowArtwork(background: url("bg")).widgetPoster == nil)
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
