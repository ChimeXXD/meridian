import Foundation

/// Where "Report a wrong time" goes (D-34): an email while the repo is private, a prefilled GitHub issue once it's
/// public. The address comes from the build (`REPORT_EMAIL` in the git-ignored `Signing.local.xcconfig`), so it's
/// never committed; empty, the email opens with no recipient.
enum ReportRoute: Equatable, Sendable {
    case email(String)
    case githubIssue

    /// Flip to `true` when the repo goes public on Day 7 (D-34): reports then become GitHub issues.
    static let repoIsPublic = false

    static var current: ReportRoute {
        repoIsPublic ? .githubIssue
            : .email(Bundle.main.object(forInfoDictionaryKey: "MeridianReportEmail") as? String ?? "")
    }
}

/// The prefilled report for one episode (SPEC core flow 6, D6-3): show, episode, the time as shown and in UTC, where
/// the time came from, the viewer's zone, the episode's ID and the app's version, then a question for the right time.
enum ReportURLBuilder {
    static let repo = "ChimeXXD/meridian"

    static func url(for drop: Drop, route: ReportRoute, now: Date, formatter: DropFormatter,
                    appVersion: String) -> URL? {
        let title = "Wrong time: \([drop.showName, drop.episodeLabel].compactMap(\.self).joined(separator: " "))"
        let body = body(for: drop, now: now, formatter: formatter, appVersion: appVersion)
        switch route {
        case .email(let address):
            // The address keeps its "@" as is: some mail apps don't decode "%40" in the recipient.
            let to = address.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            return URL(string: "mailto:\(to)?subject=\(encode(title))&body=\(encode(body))")
        case .githubIssue:
            return URL(string: "https://github.com/\(repo)/issues/new?title=\(encode(title))&body=\(encode(body))")
        }
    }

    static func body(for drop: Drop, now: Date, formatter: DropFormatter, appVersion: String) -> String {
        let utc = DropFormatter(timeZone: .gmt, locale: Locale(identifier: "en_GB"))
        let shown = ReleaseWording.outLine(drop, now: now, formatter: formatter, naming: true)
        let exact = drop.confidence == .dateOnly ? "" : " (\(utc.localDay(drop.date)) \(utc.localTime(drop.date)) UTC)"
        let lines = [
            "Show: \(drop.showName)",
            "Episode: \(drop.episodeLabel ?? "not numbered")",
            "Time shown: \(shown)\(exact)",
            "Where it came from: \(ReleaseWording.explanation(drop, broadcastZone: drop.broadcastZone, formatter: formatter))",
            "Time zone: \(ReleaseWording.zoneSummary(formatter, at: now)) (\(formatter.timeZone.identifier))",
            "Episode ID: \(drop.id)",
            "App: Meridian \(appVersion)",
            "",
            "What's the right time, and where did you see it?",
            "",
        ]
        return lines.joined(separator: "\n")
    }

    /// Percent-encodes a query value by hand: `&`, `=`, `+`, `#` and `?` inside a show's name would otherwise end the
    /// value early or turn into a space (as `TVmazeClient` does for its queries).
    private static func encode(_ text: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+?#/:@")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    }
}
