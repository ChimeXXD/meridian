import SafariServices
import SwiftUI

/// "Report a wrong time" as a sheet inside the app (D-41, AD-12): the prefilled GitHub issue in Safari's own view, so
/// the report is one swipe away from the show it's about instead of in another app.
struct ReportSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.dismissButtonStyle = .close
        safari.preferredControlTintColor = .white
        safari.preferredBarTintColor = .black
        return safari
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

/// The report page a sheet is showing; a URL alone isn't `Identifiable`.
struct ReportPage: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
