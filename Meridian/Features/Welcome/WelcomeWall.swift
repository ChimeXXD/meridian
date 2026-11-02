import Foundation

/// The art behind Welcome (Chime's picks, 2 Nov: Mindvalley's staggered rows of key art, Nike's mix of tall and wide
/// pictures, HBO's collage with anime in it). Shows airing in the next few days, the same ones Search suggests, so the
/// art is fetched at runtime and never shipped (D-37). TV and anime alternate so both halves of the app show; each
/// picture appears once; and with too little art the screen stays plain night, which is also the offline look.
struct WelcomeWall: Equatable, Sendable {
    struct Tile: Hashable, Sendable, Identifiable {
        enum Shape: Sendable { case poster, wide }
        let url: URL
        let shape: Shape
        var id: URL { url }
    }

    static let rowCount = 3
    /// Enough to run past the widest screen twice while the row drifts.
    static let perRow = 8
    /// Below this, a few lonely pictures look broken rather than full, so the night stays plain.
    static let minimum = 9
    /// How many TV shows get a TVmaze lookup for wide key art: one call each, within TVmaze's rate limit.
    static let wideTV = 3
    /// Key art is a nice extra, and TVmaze can hold a call for its Retry-After (up to 30 s, three times), so each
    /// lookup gets this long before the wall shows that show's poster instead.
    static let wideWait: Double = 3

    let rows: [[Tile]]

    /// TV and anime alternate (TV first, as it's most of the list), duplicates go, then the tiles are dealt across the
    /// rows in turn, so every row mixes both. Empty when there's less than `minimum`.
    static func arrange(tv: [Tile], anime: [Tile], rows: Int = rowCount) -> [[Tile]] {
        var merged: [Tile] = []
        var seen = Set<URL>()
        for index in 0..<max(tv.count, anime.count) {
            for tile in [tv[safe: index], anime[safe: index]].compactMap(\.self) where seen.insert(tile.url).inserted {
                merged.append(tile)
            }
        }
        guard merged.count >= minimum else { return [] }
        let dealt = merged.prefix(rows * perRow).enumerated().reduce(into: Array(repeating: [Tile](), count: rows)) {
            $0[$1.offset % rows].append($1.element)
        }
        return dealt
    }

    /// TV posters, most popular first.
    static func tvTiles(_ picks: [AiringSoon.Pick]) -> [Tile] {
        picks.compactMap { pick in
            (pick.show.image?.original ?? pick.show.image?.medium).map { Tile(url: $0, shape: .poster) }
        }
    }

    /// Anime covers, with every third show as its wide banner instead, for Nike's mix of shapes.
    static func animeTiles(_ media: [AniListMedia]) -> [Tile] {
        media.enumerated().compactMap { index, media in
            if index % 3 == 1, let banner = media.bannerImage { return Tile(url: banner, shape: .wide) }
            return (media.coverImage?.extraLarge ?? media.coverImage?.large).map { Tile(url: $0, shape: .poster) }
        }
    }

    /// Loads TV and anime at once. The first `wideTV` TV shows swap their poster for TVmaze key art when they have
    /// some. Nil when nothing came back or the task was cancelled.
    static func load(client: TVmazeClient, anilist: AniListClient, rules: RulesFile) async -> WelcomeWall? {
        async let tvPicks = AiringSoon.load(client: client, rules: rules)
        async let animeMedia = try? anilist.airingSoon(from: .now, days: 7)
        let picks = await tvPicks ?? []
        var tv = tvTiles(picks)
        let wide = await withTaskGroup(of: (Int, URL?).self) { group in
            for (index, pick) in picks.prefix(wideTV).enumerated() {
                group.addTask {
                    let url = await within(seconds: wideWait) {
                        ShowArtwork(images: (try? await client.images(showID: pick.show.id)) ?? []).background
                    }
                    return (index, url)
                }
            }
            var found: [Int: URL] = [:]
            for await (index, url) in group { if let url { found[index] = url } }
            return found
        }
        for (index, url) in wide where index < tv.count { tv[index] = Tile(url: url, shape: .wide) }
        let rows = arrange(tv: tv, anime: animeTiles(await animeMedia ?? []))
        guard !Task.isCancelled, !rows.isEmpty else { return nil }
        return WelcomeWall(rows: rows)
    }
}

/// `work`'s result, or nil if it takes longer than `seconds` (then it is cancelled).
private func within<T: Sendable>(seconds: Double, _ work: @escaping @Sendable () async -> T?) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        group.addTask { await work() }
        group.addTask { try? await Task.sleep(for: .seconds(seconds)); return nil }
        let first = await group.next() ?? nil
        group.cancelAll()
        return first
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
