import Foundation

/// Upcoming's quiet line when a refresh couldn't reach every show (D6-2, SPEC "Updated <time>"): how old the times on
/// screen are, then which shows didn't refresh. No source is named, since a show may come from TVmaze or AniList.
enum UpcomingStatus {
    /// "Updated 14:00. Couldn't refresh Silo and Frieren; pull down to try again.", with the weekday when the last full
    /// refresh was another day; nil when nothing failed. `lastUpdated` is the last refresh that reached every show.
    static func line(failed: [String], lastUpdated: Date?, now: Date, formatter: DropFormatter) -> String? {
        guard !failed.isEmpty else { return nil }
        let names = ListFormatter()
        names.locale = formatter.locale
        let shows = names.string(from: failed) ?? failed.joined(separator: ", ")
        let couldnt = "Couldn't refresh \(shows); pull down to try again."
        guard let lastUpdated else { return couldnt }
        return "Updated \(formatter.time(lastUpdated, besides: now)). \(couldnt)"
    }
}
