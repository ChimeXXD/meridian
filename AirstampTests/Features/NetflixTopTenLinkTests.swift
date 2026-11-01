import Foundation
import Testing
@testable import Airstamp

/// Netflix's terms forbid copying its Top 10 (O-13), so Search links to Netflix's own chart for the viewer's country.
@Suite("Netflix Top 10 link")
struct NetflixTopTenLinkTests {
    @Test("links to the viewer's country chart, named in plain words", arguments: [
        ("NG", "Top 10 on Netflix in Nigeria", "https://www.netflix.com/tudum/top10/nigeria/tv"),
        ("GB", "Top 10 on Netflix in United Kingdom", "https://www.netflix.com/tudum/top10/united-kingdom/tv"),
        ("US", "Top 10 on Netflix in United States", "https://www.netflix.com/tudum/top10/united-states/tv"),
        ("TT", "Top 10 on Netflix in Trinidad & Tobago", "https://www.netflix.com/tudum/top10/trinidad-and-tobago/tv"),
        ("CZ", "Top 10 on Netflix in Czechia", "https://www.netflix.com/tudum/top10/czech-republic/tv"),
        ("RE", "Top 10 on Netflix in Réunion", "https://www.netflix.com/tudum/top10/reunion/tv"),
    ])
    func link(country: String, label: String, url: String) throws {
        let link = try #require(NetflixTopTenLink(country: country))
        #expect(link.label == label)
        #expect(link.url.absoluteString == url)
    }

    @Test("no country, no link")
    func unknownCountry() {
        #expect(NetflixTopTenLink(country: nil) == nil)
        #expect(NetflixTopTenLink(country: "ZZ") == nil)
        #expect(NetflixTopTenLink(country: "001") == nil)
        #expect(NetflixTopTenLink(country: "ng") == nil)
    }
}
