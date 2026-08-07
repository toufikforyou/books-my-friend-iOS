//
//  BooksMyFriendUITests.swift
//  BooksMyFriendUITests
//
//  Created by MD TOUFIK HASAN on 5/8/26.
//

import XCTest

final class BooksMyFriendUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Launch helpers

    /// Launches past onboarding.
    ///
    /// Arguments of the form `-key value` land in `NSArgumentDomain`, which
    /// `UserDefaults.standard` reads first — so the app starts in the state the
    /// test wants without any test-only code inside the app.
    @MainActor
    private func launchApp(onboarded: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.completed", onboarded ? "YES" : "NO"]
        app.launch()
        return app
    }

    private func attach(_ app: XCUIApplication, named name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    // MARK: - Onboarding

    @MainActor
    func testOnboardingRequiresThreeGenresBeforeStarting() throws {
        let app = launchApp(onboarded: false)

        XCTAssertTrue(app.staticTexts["A library that fits\nin your pocket"].waitForExistence(timeout: 5))

        // Page through to the genre step.
        for _ in 0..<3 {
            app.buttons["Continue"].tap()
        }

        let start = app.buttons["Start reading"]
        XCTAssertTrue(start.waitForExistence(timeout: 3))
        XCTAssertFalse(start.isEnabled, "the goal picker gates on three selections")

        for genre in ["Fiction", "Sci-Fi", "Philosophy"] {
            app.buttons[genre].firstMatch.tap()
        }
        XCTAssertTrue(start.isEnabled)

        attach(app, named: "01-onboarding-genres")
        start.tap()

        XCTAssertTrue(app.staticTexts["What will you read today?"].waitForExistence(timeout: 5))
    }

    // MARK: - Discover

    @MainActor
    func testDiscoverShowsCuratedShelvesAndContinueReading() throws {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["What will you read today?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Continue Reading"].exists, "seeded progress should surface here")
        XCTAssertTrue(app.staticTexts["Editor's Spotlight"].exists)

        attach(app, named: "02-discover")
    }

    // MARK: - Book detail

    @MainActor
    func testOpeningABookShowsDetailAndChapters() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Editor's Spotlight"].waitForExistence(timeout: 5))

        // Exclude the Continue Reading card, which opens the reader instead.
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'The Lighthouse at Vessel Bay' AND NOT (label BEGINSWITH 'Continue')")
        ).firstMatch.tap()

        XCTAssertTrue(app.staticTexts["About this book"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Contents"].exists)
        XCTAssertTrue(app.staticTexts["Ratings & Reviews"].exists)

        attach(app, named: "03-book-detail")
    }

    // MARK: - Reader

    @MainActor
    func testReaderPaginatesAndTurnsPages() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Continue Reading"].waitForExistence(timeout: 5))

        // The Continue Reading card opens the reader at the saved position.
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Continue The Lighthouse'"))
            .firstMatch.tap()

        // Pagination runs off the main actor; the folio appears once it lands.
        let folio = app.staticTexts.matching(NSPredicate(format: "label CONTAINS ' / '")).firstMatch
        XCTAssertTrue(folio.waitForExistence(timeout: 20), "reader never finished paginating")

        attach(app, named: "04-reader")

        let window = app.windows.firstMatch

        // A tap in the middle of the page hides the chrome.
        let close = app.buttons["Close reader"]
        XCTAssertTrue(close.exists)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        XCTAssertFalse(close.waitForExistence(timeout: 2), "middle tap should hide the chrome")

        let before = folio.label
        // Tapping the right edge turns forward.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()

        // Re-query rather than watching `folio`: turning the page replaces the
        // whole page view, so the original element handle goes stale and would
        // report its old label forever.
        let turned = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS ' / ' AND label != %@", before))
            .firstMatch
        XCTAssertTrue(turned.waitForExistence(timeout: 8), "right-edge tap did not turn the page")

        attach(app, named: "05-reader-next-page")
    }

    @MainActor
    func testReaderDisplayOptionsChangeTheTheme() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Continue Reading"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Continue The Lighthouse'"))
            .firstMatch.tap()

        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS ' / '")).firstMatch
                .waitForExistence(timeout: 20)
        )

        app.buttons["Display options"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Theme"].waitForExistence(timeout: 5))

        app.buttons["Sepia"].firstMatch.tap()
        app.buttons["Georgia"].firstMatch.tap()

        attach(app, named: "06-reader-display-options")

        // Dismiss the sheet and confirm the reader is still on its page.
        app.swipeDown(velocity: .fast)
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS ' / '")).firstMatch
                .waitForExistence(timeout: 10)
        )
        attach(app, named: "07-reader-sepia")
    }

    @MainActor
    func testHighlightingAPassageStoresIt() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Continue Reading"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Continue The Lighthouse'"))
            .firstMatch.tap()

        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS ' / '")).firstMatch
                .waitForExistence(timeout: 20)
        )

        let highlightMenu = app.menuItems["Highlight"]

        // Press a coordinate rather than the text view element: the pages live
        // in a LazyHStack, so `textViews.firstMatch` can resolve to an
        // unrealized neighbour with an infinite frame. On CI, a single point
        // can occasionally land between lines, so try a couple of nearby
        // points before failing.
        let window = app.windows.firstMatch
        let selectionPoints = [
            CGVector(dx: 0.4, dy: 0.35),
            CGVector(dx: 0.5, dy: 0.42),
            CGVector(dx: 0.35, dy: 0.5)
        ]
        for point in selectionPoints where !highlightMenu.exists {
            window.coordinate(withNormalizedOffset: point).press(forDuration: 1.2)
            _ = highlightMenu.waitForExistence(timeout: 2)
        }

        XCTAssertTrue(highlightMenu.exists, "custom Highlight menu never appeared")
        highlightMenu.tap()

        // The edit-menu submenu exposes its rows as unlabelled cells, so the
        // colours are addressed by position — one per `HighlightColor`, in
        // declaration order, yellow first.
        let firstColor = app.cells.element(boundBy: 0)
        XCTAssertTrue(firstColor.waitForExistence(timeout: 5), "highlight colours missing")
        XCTAssertEqual(app.cells.count, 5, "expected one row per highlight colour")
        firstColor.tap()

        attach(app, named: "13-reader-highlighted")

        // It should now be listed in the book's notes.
        app.buttons["More"].firstMatch.tap()
        app.buttons["Notes & Bookmarks"].firstMatch.tap()

        let tab = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Highlights ('")).firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        XCTAssertFalse(tab.label.contains("(0)"), "the highlight was not persisted")

        attach(app, named: "14-notes")
    }

    // MARK: - Library

    @MainActor
    func testLibraryFiltersByShelf() throws {
        let app = launchApp()
        app.buttons["Library"].firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        attach(app, named: "08-library")

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Finished'")).firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'book'")).firstMatch
                .waitForExistence(timeout: 5)
        )
        attach(app, named: "09-library-finished")
    }

    // MARK: - Search

    @MainActor
    func testSearchFindsABookByTitle() throws {
        let app = launchApp()
        app.buttons["Search"].firstMatch.tap()

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("orbitals")

        XCTAssertTrue(app.staticTexts["Orbitals"].waitForExistence(timeout: 5))
        attach(app, named: "10-search-results")
    }

    // MARK: - Profile

    @MainActor
    func testProfileShowsStatsAndOpensSettings() throws {
        let app = launchApp()
        app.buttons["You"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["Day streak"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Books finished"].exists)
        XCTAssertTrue(app.staticTexts["This week"].exists)
        attach(app, named: "11-profile")

        app.buttons["Settings"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        attach(app, named: "12-settings")
    }
}
