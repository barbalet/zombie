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

    func testScenarioBrowserStartsPlayMode() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["zombie"].waitForExistence(timeout: 8))

        let search = app.textFields["Search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        search.typeText("Drummuckavall")

        let drummuckavall = app.staticTexts["Drummuckavall Ambush"].firstMatch
        XCTAssertTrue(drummuckavall.waitForExistence(timeout: 8))
        drummuckavall.tap()

        let startGame = app.buttons["Start Game"].firstMatch
        XCTAssertTrue(startGame.waitForExistence(timeout: 8))
        XCTAssertTrue(startGame.isEnabled)
        startGame.tap()

        let playModeStarted = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Play Mode started")).firstMatch
        XCTAssertTrue(playModeStarted.waitForExistence(timeout: 8))

        XCTAssertTrue(app.staticTexts["Actor Inspector"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Weapon")).firstMatch.exists)

        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 8))
        cancel.tap()

        let attack = app.buttons["Attack"].firstMatch
        XCTAssertTrue(attack.waitForExistence(timeout: 8))
        attack.tap()

        let blockedMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Select an actor")).firstMatch
        XCTAssertTrue(blockedMessage.waitForExistence(timeout: 8))
    }

    func testTutorialScenarioCompletes() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["zombie"].waitForExistence(timeout: 8))

        let search = app.textFields["Search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        search.typeText("Play Mode Tutorial")

        let tutorial = app.staticTexts["Play Mode Tutorial"].firstMatch
        XCTAssertTrue(tutorial.waitForExistence(timeout: 8))
        tutorial.tap()

        let startGame = app.buttons["Start Game"].firstMatch
        XCTAssertTrue(startGame.waitForExistence(timeout: 8))
        startGame.tap()

        XCTAssertTrue(app.staticTexts["Tutorial Steps"].waitForExistence(timeout: 8))

        let completeTutorial = app.buttons["Complete Tutorial"].firstMatch
        XCTAssertTrue(completeTutorial.waitForExistence(timeout: 8))
        completeTutorial.tap()

        let completeStatus = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "tutorial complete")).firstMatch
        XCTAssertTrue(completeStatus.waitForExistence(timeout: 8))
    }

    func testVehicleScenarioStartsAbstractPlayMode() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["zombie"].waitForExistence(timeout: 8))

        let search = app.textFields["Search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        search.typeText("Dungiven")

        let dungiven = app.staticTexts["Dungiven Landmine and Gun Attack"].firstMatch
        XCTAssertTrue(dungiven.waitForExistence(timeout: 8))
        dungiven.tap()

        let startGame = app.buttons["Start Game"].firstMatch
        XCTAssertTrue(startGame.waitForExistence(timeout: 8))
        XCTAssertTrue(startGame.isEnabled)
        startGame.tap()

        XCTAssertTrue(app.staticTexts["Abstract Play Mode"].waitForExistence(timeout: 8))

        let advance = app.buttons["Advance Route"].firstMatch
        XCTAssertTrue(advance.waitForExistence(timeout: 8))
        XCTAssertTrue(advance.isEnabled)
        advance.tap()

        let resolve = app.buttons["Resolve"].firstMatch
        XCTAssertTrue(resolve.waitForExistence(timeout: 8))
        XCTAssertTrue(resolve.isEnabled)
        resolve.tap()

        let routeEvent = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "vehicle-route")).firstMatch
        XCTAssertTrue(routeEvent.waitForExistence(timeout: 8))
    }

    func testDeferredScenarioCannotStartPlayMode() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["zombie"].waitForExistence(timeout: 8))

        let search = app.textFields["Search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        search.typeText("1985 Newry Mortar")

        let mortar = app.staticTexts["1985 Newry Mortar Attack"].firstMatch
        XCTAssertTrue(mortar.waitForExistence(timeout: 8))
        mortar.tap()

        let startGame = app.buttons["Start Game"].firstMatch
        XCTAssertTrue(startGame.waitForExistence(timeout: 8))
        XCTAssertFalse(startGame.isEnabled)
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
