//
//  SearchSessionTests.swift
//  MenuetTests
//

import XCTest


@MainActor
class SearchSessionTests: XCTestCase {

  // Standard fixture used by most tests. Two top-level menus with five
  // items chosen so that several queries return different shapes:
  //   "save"  → single match
  //   "n"     → multiple matches across one menu
  //   "p"     → multiple matches across two menus
  //   "xyzzy" → no matches
  private func makeSession() -> SearchSession {
    return makeSession(menuBar: makeMenuBar([
      makeMenuBarItem(title: "File", items: [
        makeMenuItem("New",        cmdChar: "N"),
        makeMenuItem("New Window", cmdChar: "N", modifiers: 1),
        makeMenuItem("Save",       cmdChar: "S"),
        makeMenuItem("Print",      cmdChar: "P"),
      ]),
      makeMenuBarItem(title: "Edit", items: [
        makeMenuItem("Copy",  cmdChar: "C"),
        makeMenuItem("Paste", cmdChar: "V"),
      ]),
    ]))
  }

  private func makeSession(menuBar: FakeAXElement) -> SearchSession {
    let provider = IndexProvider()
    let app = FakeAXApplication(menuBar: menuBar)
    AXMenuWalker(application: app)
      .walk(visitor: AXMenuIndexer(index: provider.index))
    return SearchSession(menus: provider)
  }

  // MARK: - Typing

  func testTypingASingleMatchHighlightsThatItem() {
    let session = makeSession()

    session.search("save")

    XCTAssertEqual(session.activeItem?.title, "Save")
    XCTAssertEqual(session.searchResults.map(\.title), ["Save"])
  }

  func testTypingHighlightsBestMatchWhenManyHit() {
    let session = makeSession()

    session.search("p")

    // Whichever ordering FuzzyMatch decides, the first result is the one
    // the user sees as highlighted — that's the contract the panel
    // depends on.
    XCTAssertFalse(session.searchResults.isEmpty)
    XCTAssertEqual(session.activeItem, session.searchResults.first)
  }

  func testTypingNoMatchLeavesNoActiveItem() {
    let session = makeSession()

    session.search("xyzzy")

    XCTAssertNil(session.activeItem)
    XCTAssertTrue(session.searchResults.isEmpty)
    XCTAssertFalse(session.hasResults())
  }

  func testEmptyingTheQueryClearsResults() {
    let session = makeSession()
    session.search("save")
    XCTAssertNotNil(session.activeItem)

    session.search("")

    XCTAssertNil(session.activeItem)
    XCTAssertTrue(session.searchResults.isEmpty)
    XCTAssertFalse(session.hasResults())
  }

  func testRefiningTheQueryUpdatesTheActiveItem() {
    // "n" matches New, New Window, Print (contains 'n'/'n'), and any
    // other titles containing the letter. "new" narrows to just the two
    // "New ..." items, so the active item must end up in that subset.
    let session = makeSession()
    session.search("n")
    let firstActive = session.activeItem
    XCTAssertNotNil(firstActive)

    session.search("new")

    XCTAssertNotNil(session.activeItem)
    XCTAssertTrue(session.activeItem!.title.lowercased().hasPrefix("new"),
                  "Refined query should narrow to a 'New ...' item, got \(session.activeItem!.title)")
  }

  // MARK: - Arrow keys

  func testDownArrowAdvancesThroughResults() {
    let session = makeSession()
    session.search("p")  // multiple matches
    XCTAssertGreaterThan(session.searchResults.count, 1, "fixture must produce multiple matches for this test")
    let first = session.activeItem

    session.selectNext()

    XCTAssertNotEqual(session.activeItem, first)
    XCTAssertEqual(session.activeItem, session.searchResults[1])
  }

  func testDownArrowFromLastResultWrapsToFirst() {
    let session = makeSession()
    session.search("p")
    let count = session.searchResults.count
    XCTAssertGreaterThan(count, 1)

    // Walk to the last result, then step once more.
    for _ in 1..<count { session.selectNext() }
    XCTAssertEqual(session.activeItem, session.searchResults.last)

    session.selectNext()

    XCTAssertEqual(session.activeItem, session.searchResults.first)
  }

  func testUpArrowMovesBackThroughResults() {
    let session = makeSession()
    session.search("p")
    XCTAssertGreaterThan(session.searchResults.count, 1)
    session.selectNext()
    let second = session.activeItem

    session.selectPrevious()

    XCTAssertEqual(session.activeItem, session.searchResults.first)
    XCTAssertNotEqual(session.activeItem, second)
  }

  func testUpArrowFromFirstResultWrapsToLast() {
    let session = makeSession()
    session.search("p")
    XCTAssertEqual(session.activeItem, session.searchResults.first)

    session.selectPrevious()

    XCTAssertEqual(session.activeItem, session.searchResults.last)
  }

  func testArrowKeysAreNoopWhenNoResults() {
    let session = makeSession()
    session.search("xyzzy")

    session.selectNext()
    XCTAssertNil(session.activeItem)
    XCTAssertTrue(session.searchResults.isEmpty)

    session.selectPrevious()
    XCTAssertNil(session.activeItem)
    XCTAssertTrue(session.searchResults.isEmpty)
  }

  // MARK: - Clearing

  func testClearResetsQueryResultsAndSelection() {
    let session = makeSession()
    session.search("save")
    session.query = "save"  // mirrors what the TextField binding does
    XCTAssertNotNil(session.activeItem)

    session.clear()

    XCTAssertEqual(session.query, "")
    XCTAssertNil(session.activeItem)
    XCTAssertTrue(session.searchResults.isEmpty)
    XCTAssertFalse(session.hasResults())
  }

  // MARK: - Shortcut matching

  // SearchPanel.performKeyEquivalent dispatches by asking
  // findMatchingResult for the first item whose command matches the
  // typed event. The session has to surface a hit when one exists.
  func testFindMatchingResultReturnsAResultSatisfyingThePredicate() {
    let session = makeSession()
    session.search("save")

    let hit = session.findMatchingResult { $0.title == "Save" }

    XCTAssertEqual(hit?.title, "Save")
  }

  func testFindMatchingResultReturnsNilWhenNothingMatches() {
    let session = makeSession()
    session.search("save")

    let hit = session.findMatchingResult { $0.title == "Print" }

    XCTAssertNil(hit)
  }

  // MARK: - hasResults flag

  func testHasResultsReflectsCurrentState() {
    let session = makeSession()
    XCTAssertFalse(session.hasResults(), "fresh session has no results")

    session.search("save")
    XCTAssertTrue(session.hasResults())

    session.search("xyzzy")
    XCTAssertFalse(session.hasResults())

    session.search("save")
    session.clear()
    XCTAssertFalse(session.hasResults())
  }
}
