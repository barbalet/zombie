import XCTest

final class ZombieUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testScenarioBrowserLoadsAndRunsPreview() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["zombie"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["All"].exists)
        XCTAssertTrue(app.staticTexts["Scenarios"].exists)

        let runPreview = app.buttons["Run Preview"].firstMatch
        XCTAssertTrue(runPreview.waitForExistence(timeout: 8))
        runPreview.tap()

        let regressionPreview = app.staticTexts["Regression Preview"].firstMatch
        XCTAssertTrue(regressionPreview.waitForExistence(timeout: 8))
    }

    func testSearchFindsAdvancedScenario() throws {
        let app = XCUIApplication()
        app.launch()

        let search = app.textFields["Search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        search.typeText("Crossmaglen")

        let newryRoad = app.staticTexts["Battle of Newry Road"].firstMatch
        XCTAssertTrue(newryRoad.waitForExistence(timeout: 8))
        newryRoad.tap()

        let runPreview = app.buttons["Run Preview"].firstMatch
        XCTAssertTrue(runPreview.waitForExistence(timeout: 8))
        runPreview.tap()

        let regressionPreview = app.staticTexts["Regression Preview"].firstMatch
        XCTAssertTrue(regressionPreview.waitForExistence(timeout: 8))
    }
}
