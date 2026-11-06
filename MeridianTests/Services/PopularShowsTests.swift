import Foundation
import Testing
@testable import Meridian

/// The bundled popular list (`rules/popular-shows.json`, D-66): what `scripts/build-popular-shows.py` promises, checked
/// on the file the app ships, so a bad rebuild fails here rather than on the phone.
@Suite("Popular shows list")
struct PopularShowsTests {
    @Test("the bundled list loads, most viewed first, with no show twice")
    func loads() throws {
        let list = PopularShows.loadBundled()
        #expect(list.shows.count >= 50)
        #expect(list.shows.map(\.views) == list.shows.map(\.views).sorted(by: >))
        #expect(Set(list.shows.map(\.show.id)).count == list.shows.count)
    }

    @Test("every show is scripted or animated and last aired in the year before the list was built")
    func pastYearOnly() throws {
        let list = PopularShows.loadBundled()
        let built = try #require(WallClock.parseDate(list.updated))
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let day = try #require(utc.date(from: DateComponents(year: built.year, month: built.month, day: built.day)))
        let yearAgo = DropFormatter(timeZone: .gmt).localDay(day, addingDays: -365)
        for entry in list.shows {
            #expect(["Scripted", "Animation"].contains(entry.show.type ?? ""), "\(entry.show.name)")
            #expect((entry.lastAired ?? "") >= yearAgo && (entry.lastAired ?? "") <= list.updated, "\(entry.show.name)")
            if let start = entry.seasonStart { #expect(start <= list.updated, "\(entry.show.name)") }
        }
    }

    @Test("each of the 8 big streamers has shows on the list, so its chip shows (an empty platform gets none, D-66)")
    func streamersHaveShows() {
        let networks = PopularShows.loadBundled().shows.compactMap { ($0.show.network ?? $0.show.webChannel)?.name }
        for service in PopularServices.all.prefix(8) {
            #expect(networks.contains { service.names.contains($0) }, "\(service.label)")
        }
    }
}
