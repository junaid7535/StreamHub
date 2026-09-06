import XCTest

final class StreamHubUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch_showsHomeScreen() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.navigationBars["StreamHub"]
                .waitForExistence(timeout: 3)
        )
    }

    @MainActor
    func testLibraryMenu_canNavigateToBookmarksAndHistory() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryMenuButton = app.buttons["Open Library Menu"]

        XCTAssertTrue(
            libraryMenuButton.waitForExistence(timeout: 3)
        )

        // Navigate to Bookmarks
        libraryMenuButton.tap()
        app.buttons["Bookmarks"].tap()

        XCTAssertTrue(
            app.navigationBars["Bookmarks"]
                .waitForExistence(timeout: 3)
        )

        // Return to Home
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(
            app.navigationBars["StreamHub"]
                .waitForExistence(timeout: 3)
        )

        // Navigate to History
        libraryMenuButton.tap()
        app.buttons["History"].tap()

        XCTAssertTrue(
            app.navigationBars["History"]
                .waitForExistence(timeout: 3)
        )
    }
}
