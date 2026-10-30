import Foundation
import SwiftData
import Testing
@testable import Airstamp

/// The shows you follow live in SwiftData on the phone (local-first, no account). Upcoming is built from this list.
@Suite("Follow store")
@MainActor
struct FollowStoreTests {
    static func container() throws -> ModelContainer {
        try ModelContainer(for: FollowedShow.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    static let silo = FollowStore.Show(catalog: .tvmaze, id: 38052, name: "Silo", year: 2023, network: "Apple TV")

    @Test("a followed show persists and reads back from a fresh context")
    func followPersists() throws {
        let container = try Self.container()
        try FollowStore(context: ModelContext(container)).follow(Self.silo)
        let shows = try FollowStore(context: ModelContext(container)).shows()
        #expect(shows.map(\.name) == ["Silo"])
        #expect(shows.first?.key == "tvmaze:38052")
        #expect(shows.first?.liveActivity == true)
        #expect(shows.first?.animeOffsetMinutes == 0)
    }

    @Test("following the same show twice keeps one entry")
    func noDuplicates() throws {
        let store = FollowStore(context: ModelContext(try Self.container()))
        try store.follow(Self.silo)
        try store.follow(Self.silo)
        #expect(try store.shows().count == 1)
    }

    @Test("unfollow removes the show, and isFollowing says so")
    func unfollow() throws {
        let store = FollowStore(context: ModelContext(try Self.container()))
        try store.follow(Self.silo)
        #expect(try store.isFollowing(catalog: .tvmaze, id: 38052))
        try store.unfollow(catalog: .tvmaze, id: 38052)
        #expect(try store.shows().isEmpty)
        #expect(try !store.isFollowing(catalog: .tvmaze, id: 38052))
    }

    @Test("the same id in two catalogs is two different shows")
    func catalogsAreSeparate() throws {
        let store = FollowStore(context: ModelContext(try Self.container()))
        try store.follow(Self.silo)
        try store.follow(.init(catalog: .anilist, id: 38052, name: "Some anime", year: 2024, network: nil))
        #expect(try store.shows().count == 2)
    }
}
