import XCTest

/// Performs the release-night demo for the case study video, on the simulator, while `xcrun simctl io … recordVideo`
/// films it: a test Live Activity one minute from release, the island ticking on the Home Screen, pressed to expand,
/// the Lock Screen banner, then "Out now". Runs only with `TEST_RUNNER_MERIDIAN_DEMO=1`, so CI and the screen checks
/// never pick it up. Real app, real system UI: nothing here is drawn for the video. It films the plain "Debug Show";
/// on the phone, Settings › Debug › "Live Activity for <show>" films a real episode with its art instead.
final class DemoRecordingTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["MERIDIAN_DEMO"] == "1", "only for the demo recording")
        continueAfterFailure = true
    }

    /// Press and hold the island, the way you expand it on a phone.
    @MainActor
    private func expandIsland(_ springboard: XCUIApplication, holdFor seconds: TimeInterval) {
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.028)).press(forDuration: 0.8)
        Thread.sleep(forTimeInterval: seconds)
        // A tap on the wallpaper below the icons folds it back.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).tap()
    }

    @MainActor
    func test_releaseNightDemo() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let app = XCUIApplication()
        // The fake drop is one minute away, so the activity starts at once and reaches "Out now" on camera.
        app.launchArguments = ["-welcomeDone", "YES", "-fakeActivity", "1"]
        app.launch()
        Thread.sleep(forTimeInterval: 5)

        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 5)            // the compact island ticks on the Home Screen
        expandIsland(springboard, holdFor: 7)       // the show, its time and the countdown
        Thread.sleep(forTimeInterval: 3)

        // The Lock Screen banner: pulled down from the top-left corner, then pushed back up.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.005))
            .press(forDuration: 0.05, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.6)))
        Thread.sleep(forTimeInterval: 7)
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99))
            .press(forDuration: 0.05, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))

        // Wait out the minute, then show "Out now" in the island.
        Thread.sleep(forTimeInterval: 30)
        expandIsland(springboard, holdFor: 6)
        Thread.sleep(forTimeInterval: 3)
    }
}
