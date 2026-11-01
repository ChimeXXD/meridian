import Foundation
import SwiftData

/// Follows and unfollows shows. A thin layer over a `ModelContext`, so views and view models never build SwiftData
/// queries themselves.
@MainActor
struct FollowStore {
    /// What Search hands over when you follow a result.
    struct Show: Hashable, Sendable {
        var catalog: Catalog
        var id: Int
        var name: String
        var year: Int?
        var network: String?
    }

    let context: ModelContext

    /// Following a show you already follow keeps the one entry (and its settings).
    func follow(_ show: Show) throws {
        guard try find(catalog: show.catalog, id: show.id) == nil else { return }
        context.insert(FollowedShow(catalog: show.catalog, catalogID: show.id, name: show.name, year: show.year,
                                    network: show.network))
        try context.save()
    }

    func unfollow(catalog: Catalog, id: Int) throws {
        if let show = try find(catalog: catalog, id: id) {
            context.delete(show)
            try context.save()
        }
    }

    func isFollowing(catalog: Catalog, id: Int) throws -> Bool {
        try find(catalog: catalog, id: id) != nil
    }

    /// Oldest first, so the list keeps a stable order before times are known.
    func shows() throws -> [FollowedShow] {
        try context.fetch(FetchDescriptor<FollowedShow>(sortBy: [SortDescriptor(\.followedAt)]))
    }

    private func find(catalog: Catalog, id: Int) throws -> FollowedShow? {
        let key = FollowedShow.key(catalog: catalog, id: id)
        var descriptor = FetchDescriptor<FollowedShow>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
