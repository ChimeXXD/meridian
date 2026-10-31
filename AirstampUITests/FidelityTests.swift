import XCTest

/// Screen checks (D3-1): each `fidelity/inventory/<screen>.json` lists the accessibility IDs a screen must show and,
/// where the UI brief fixes the wording, the exact text. Each test launches the real app on that screen, checks every
/// item, and attaches a screenshot (also written to `$FIDELITY_SHOTS` when set). Run with `fidelity/verify-screen.sh`.
final class FidelityTests: XCTestCase {
    struct Inventory: Decodable {
        struct Item: Decodable {
            let id: String
            var text: String?
            var prefix: String?
            /// Below the first screen: scroll down before looking.
            var scroll: Bool?
        }

        let screen: String
        let launch: [String]
        let items: [Item]
    }

    override func setUp() {
        continueAfterFailure = true
    }

    func test_welcome() throws { try check("welcome") }
    func test_upcoming() throws { try check("upcoming") }
    func test_upcoming_empty() throws { try check("upcoming-empty") }
    func test_detail() throws { try check("detail") }
    func test_settings() throws { try check("settings") }

    private func check(_ screen: String) throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: screen, withExtension: "json",
                                                                 subdirectory: "inventory"),
                                "no inventory for \(screen)")
        let inventory = try JSONDecoder().decode(Inventory.self, from: Data(contentsOf: url))
        let app = XCUIApplication()
        app.launchArguments = inventory.launch
        app.launch()
        capture(app, name: screen)
        var scrolled = false
        for item in inventory.items {
            if item.scroll == true, !scrolled {
                app.swipeUp(velocity: .slow)
                scrolled = true
            }
            let element = app.descendants(matching: .any)[item.id].firstMatch
            guard element.waitForExistence(timeout: 15) else {
                XCTFail("\(screen): missing \(item.id)")
                continue
            }
            let shown = element.label.isEmpty ? (element.value as? String ?? "") : element.label
            if let text = item.text {
                XCTAssertEqual(shown, text, "\(screen): \(item.id) copy")
            }
            if let prefix = item.prefix {
                XCTAssertTrue(shown.hasPrefix(prefix), "\(screen): \(item.id) reads \"\(shown)\", expected \"\(prefix)…\"")
            }
        }
        if scrolled { capture(app, name: "\(screen)-scrolled") }
    }

    private func capture(_ app: XCUIApplication, name: String) {
        sleep(3)  // let artwork fade in
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let folder = ProcessInfo.processInfo.environment["FIDELITY_SHOTS"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: folder).appendingPathComponent("\(name).png"))
        }
    }
}
