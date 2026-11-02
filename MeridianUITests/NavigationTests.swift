import XCTest

/// Swiping from the left edge goes back, as in every iOS app (Chime, 2 Nov: it didn't, because Show detail and the
/// show page hid the system bar for a drawn back button). Each test pushes a screen, swipes, and checks it's gone.
final class NavigationTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func swipeFromLeftEdge(_ app: XCUIApplication) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    func test_showDetailSwipesBack() {
        let app = XCUIApplication()
        app.launchArguments = ["-designPreview"]
        app.launch()
        let hero = app.buttons["upcoming-hero"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        hero.tap()
        let detail = app.descendants(matching: .any)["detail-next"]
        XCTAssertTrue(detail.waitForExistence(timeout: 5), "Show detail didn't open")

        swipeFromLeftEdge(app)
        XCTAssertTrue(detail.waitForNonExistence(timeout: 5), "the edge swipe didn't go back")
        XCTAssertTrue(hero.waitForExistence(timeout: 5))
    }

    func test_showPageSwipesBack() {
        let app = XCUIApplication()
        app.launchArguments = ["-inMemoryStore", "-welcomeDone", "YES", "-tab", "search", "-query", "Silo",
                               "-openFirstResult", "YES"]
        app.launch()
        let art = app.descendants(matching: .any)["show-preview-art"]
        XCTAssertTrue(art.waitForExistence(timeout: 20), "the show page didn't open (needs TVmaze)")

        swipeFromLeftEdge(app)
        XCTAssertTrue(art.waitForNonExistence(timeout: 5), "the edge swipe didn't go back")
    }
}
