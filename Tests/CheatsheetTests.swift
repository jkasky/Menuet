//
//  CheatsheetTests.swift
//  MenuetTests
//

import XCTest


private func buildIndex(_ menuBar: FakeAXElement, indexAppleMenu: Bool = true) -> MenuIndex {
  let app = FakeAXApplication(menuBar: menuBar)
  let index = MenuIndex()
  AXMenuWalker(application: app).walk(
    visitor: AXMenuIndexer(index: index, indexAppleMenu: indexAppleMenu))
  return index
}


class MenuIndexShortcutsTests: XCTestCase {

  func testItemsWithShortcutsExcludesShortcutless() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [
        makeMenuItem("New", cmdChar: "N"),
        makeMenuItem("Open Recent"),
        makeMenuItem("Save", cmdChar: "S"),
      ]),
    ])

    let titles = buildIndex(menuBar).itemsWithShortcuts().map(\.title)

    XCTAssertEqual(titles, ["New", "Save"])
  }

  func testItemsWithShortcutsEmptyWhenNoneHaveShortcuts() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "Help", items: [makeMenuItem("About")]),
    ])

    XCTAssertTrue(buildIndex(menuBar).itemsWithShortcuts().isEmpty)
  }
}


@MainActor
class CheatsheetGroupingTests: XCTestCase {

  func testGroupsByTopLevelMenuPreservingOrder() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [
        makeMenuItem("New",  cmdChar: "N"),
        makeMenuItem("Save", cmdChar: "S"),
      ]),
      makeMenuBarItem(title: "Edit", items: [
        makeMenuItem("Copy",  cmdChar: "C"),
        makeMenuItem("Paste", cmdChar: "V"),
      ]),
    ])
    let items = buildIndex(menuBar).itemsWithShortcuts()

    let groups = CheatsheetSession.groupForCheatsheet(items)

    XCTAssertEqual(groups.map(\.menu), ["File", "Edit"])
    XCTAssertEqual(groups[0].items.map(\.title), ["New", "Save"])
    XCTAssertEqual(groups[1].items.map(\.title), ["Copy", "Paste"])
  }

  func testExcludesAppleMenu() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "Apple", items: [makeMenuItem("Force Quit", cmdChar: "Q", modifiers: 1)]),
      makeMenuBarItem(title: "File",  items: [makeMenuItem("New",        cmdChar: "N")]),
    ], applePrefixed: false)
    // indexAppleMenu: true ensures Apple items reach the index — grouping
    // should still drop them.
    let items = buildIndex(menuBar, indexAppleMenu: true).itemsWithShortcuts()

    let groups = CheatsheetSession.groupForCheatsheet(items)

    XCTAssertEqual(groups.map(\.menu), ["File"])
  }

  // Apple menu detection is positional, not title-based: AX's title for
  // the system menu is implementation-defined (the visible UI is the
  // apple glyph). Use a deliberately unrelated title at position 0 to
  // verify grouping doesn't fall back to a string check.
  func testExcludesAppleMenuByPositionRegardlessOfTitle() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "NotApple", items: [makeMenuItem("Force Quit", cmdChar: "Q", modifiers: 1)]),
      makeMenuBarItem(title: "File",     items: [makeMenuItem("New",        cmdChar: "N")]),
    ], applePrefixed: false)
    let items = buildIndex(menuBar, indexAppleMenu: true).itemsWithShortcuts()

    let groups = CheatsheetSession.groupForCheatsheet(items)

    XCTAssertEqual(groups.map(\.menu), ["File"])
  }

  func testEmptyInputProducesNoGroups() {
    XCTAssertTrue(CheatsheetSession.groupForCheatsheet([]).isEmpty)
  }
}


@MainActor
class CheatsheetSearchTests: XCTestCase {

  private func makeCheetsheetSession() -> CheatsheetSession {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [
        makeMenuItem("New",       cmdChar: "N"),
        makeMenuItem("New Window", cmdChar: "N", modifiers: 1),
        makeMenuItem("Save",      cmdChar: "S"),
      ]),
      makeMenuBarItem(title: "Edit", items: [
        makeMenuItem("Copy",  cmdChar: "C"),
        makeMenuItem("Paste", cmdChar: "V"),
      ]),
    ])
    let items = buildIndex(menuBar).itemsWithShortcuts()
    let session = CheatsheetSession(menus: IndexProvider())
    session.groups = CheatsheetSession.groupForCheatsheet(items)
    return session
  }

  func testTypingHighlightsBestMatch() {
    let session = makeCheetsheetSession()

    session.append("c")

    XCTAssertEqual(session.query, "c")
    XCTAssertEqual(session.activeItem?.title, "Copy")
    XCTAssertTrue(session.matchItems.contains(session.activeItem!))
  }

  func testTabCyclesAndLoops() {
    let session = makeCheetsheetSession()

    session.append("n")  // Matches "New" and "New Window"
    let first = session.activeItem
    XCTAssertNotNil(first)

    session.selectNextMatch()
    let second = session.activeItem
    XCTAssertNotNil(second)
    XCTAssertNotEqual(first, second)

    session.selectNextMatch()
    XCTAssertEqual(session.activeItem, first, "Tab past end should loop to first")
  }

  func testTabFollowsDisplayOrderNotScore() {
    // "Save" (File menu, displayed third) is a stronger fuzzy match for
    // "sa" than "Paste" (Edit menu, displayed fifth) — but Tab should
    // still walk top-to-bottom through both in display order.
    let session = makeCheetsheetSession()
    session.append("a")  // Matches Save, Paste

    let displayOrder = session.groups
      .flatMap { $0.items }
      .filter { session.matchItems.contains($0) }
    let startIndex = displayOrder.firstIndex(of: session.activeItem!)!
    let expected = (0..<displayOrder.count).map { displayOrder[(startIndex + $0) % displayOrder.count] }

    let visited = sequenceOf(session, count: displayOrder.count)
    XCTAssertEqual(visited, expected)
  }

  // Returns the sequence of active items across `count` Tab presses,
  // starting from whatever is currently active.
  private func sequenceOf(_ session: CheatsheetSession, count: Int) -> [MenuItem] {
    var items: [MenuItem] = []
    if let item = session.activeItem { items.append(item) }
    for _ in 1..<count {
      session.selectNextMatch()
      if let item = session.activeItem { items.append(item) }
    }
    return items
  }

  func testClearQueryResetsState() {
    let session = makeCheetsheetSession()
    session.append("c")
    XCTAssertNotNil(session.activeItem)

    session.clearQuery()

    XCTAssertEqual(session.query, "")
    XCTAssertNil(session.activeItem)
    XCTAssertTrue(session.matchItems.isEmpty)
  }

  func testBackspaceOnEmptyIsNoop() {
    let session = makeCheetsheetSession()

    session.backspace()

    XCTAssertEqual(session.query, "")
    XCTAssertNil(session.activeItem)
  }

  func testBackspaceShortensQueryAndRecomputes() {
    let session = makeCheetsheetSession()
    session.append("c")
    session.append("o")
    session.append("z")  // No item matches "coz"
    XCTAssertNil(session.activeItem)

    session.backspace()  // Back to "co" → matches "Copy"

    XCTAssertEqual(session.query, "co")
    XCTAssertEqual(session.activeItem?.title, "Copy")
  }

  func testNoMatchesLeavesActiveNil() {
    let session = makeCheetsheetSession()

    session.append("z")

    XCTAssertNil(session.activeItem)
    XCTAssertTrue(session.matchItems.isEmpty)
  }

  func testSelectNextWithNoMatchesIsNoop() {
    let session = makeCheetsheetSession()
    session.append("z")

    session.selectNextMatch()

    XCTAssertNil(session.activeItem)
  }
}


// AX convention: AXMenuItemCmdModifiers' bit 8 is *set* when the item
// does NOT use Command. So a raw value of 0 has Command; raw value 8 has
// no Command. Fixture inputs below are AX raw ints, matching what AX
// would emit; assertions on `Modifiers` use the positive surface
// (`.command`, `[.control, .command]`, …).
@MainActor
class CheatsheetModifierFilterTests: XCTestCase {

  private static let hasCommand = 0
  private static let noCommand = 8
  private static let controlNoCmd = 4 | 8
  private static let optionNoCmd = 2 | 8
  private static let shiftNoCmd = 1 | 8
  private static let controlAndCommand = 4

  private func makeCheetsheetSession(withItems items: [FakeAXElement], inMenu menuName: String) -> CheatsheetSession {
    let menuBar = makeMenuBar([makeMenuBarItem(title: menuName, items: items)])
    let itemsIndexed = buildIndex(menuBar).itemsWithShortcuts()
    let session = CheatsheetSession(menus: IndexProvider())
    session.groups = CheatsheetSession.groupForCheatsheet(itemsIndexed)
    return session
  }

  // ---------------------------------------------------------------- Modifiers.containsFilter

  func testEmptyFilterMatchesAllModifiers() {
    XCTAssertTrue(Modifiers().containsFilter([]))
    XCTAssertTrue(Modifiers([.control]).containsFilter([]))
    XCTAssertTrue(Modifiers.command.containsFilter([]))
  }

  func testControlFilterMatchesControlItems() {
    let flags: NSEvent.ModifierFlags = [.control]
    XCTAssertTrue(Modifiers([.control]).containsFilter(flags))
    XCTAssertFalse(Modifiers().containsFilter(flags))
    XCTAssertFalse(Modifiers([.control, .command]).containsFilter(flags))
    XCTAssertFalse(Modifiers.command.containsFilter(flags))
  }

  func testCommandFilterMatchesCommandItems() {
    let flags: NSEvent.ModifierFlags = [.command]
    XCTAssertTrue(Modifiers.command.containsFilter(flags))
    XCTAssertFalse(Modifiers().containsFilter(flags))
    XCTAssertFalse(Modifiers([.control]).containsFilter(flags))
  }

  func testOptionFilterMatchesOptionItems() {
    let flags: NSEvent.ModifierFlags = [.option]
    XCTAssertTrue(Modifiers([.option]).containsFilter(flags))
    XCTAssertFalse(Modifiers([.control]).containsFilter(flags))
  }

  func testShiftFilterMatchesShiftItems() {
    let flags: NSEvent.ModifierFlags = [.shift]
    XCTAssertTrue(Modifiers([.shift]).containsFilter(flags))
    XCTAssertFalse(Modifiers([.option]).containsFilter(flags))
  }

  func testCombinedFilterMatchesItemsWithAllModifiers() {
    let flags: NSEvent.ModifierFlags = [.control, .command]
    XCTAssertTrue(Modifiers([.control, .command]).containsFilter(flags))
    XCTAssertFalse(Modifiers().containsFilter(flags))
    XCTAssertFalse(Modifiers.command.containsFilter(flags))
    XCTAssertFalse(Modifiers([.control]).containsFilter(flags))
  }

  // ---------------------------------------------------------------- CheatsheetSession filteredGroups

  func testFilteredGroupsExcludesNonMatchingItems() {
    let session = makeCheetsheetSession(withItems: [
      makeMenuItem("Copy", cmdChar: "C", modifiers: Self.controlNoCmd),
      makeMenuItem("Paste", cmdChar: "V", modifiers: Self.noCommand),
    ], inMenu: "Edit")

    session.updateModifierFilter([.control])

    let filtered = session.filteredGroups

    XCTAssertEqual(filtered.count, 1)
    XCTAssertEqual(filtered[0].items.count, 1)
    XCTAssertEqual(filtered[0].items[0].title, "Copy")
  }

  func testEmptyFilterReturnsAllGroups() {
    let session = makeCheetsheetSession(withItems: [
      makeMenuItem("Copy", cmdChar: "C", modifiers: Self.controlNoCmd),
      makeMenuItem("Paste", cmdChar: "V", modifiers: Self.noCommand),
    ], inMenu: "Edit")

    session.updateModifierFilter([])

    let filtered = session.filteredGroups

    XCTAssertEqual(filtered.count, 1)
    XCTAssertEqual(filtered[0].items.count, 2)
  }

  func testFilterClearingShowsAllItemsAgain() {
    let session = makeCheetsheetSession(withItems: [
      makeMenuItem("Copy", cmdChar: "C", modifiers: Self.controlNoCmd),
      makeMenuItem("Paste", cmdChar: "V", modifiers: Self.noCommand),
    ], inMenu: "Edit")

    session.updateModifierFilter([.control])
    XCTAssertEqual(session.filteredGroups[0].items.count, 1)

    session.updateModifierFilter([])
    XCTAssertEqual(session.filteredGroups[0].items.count, 2)
  }

  func testCheatsheetClearQueryResetsModifierFilter() {
    let session = makeCheetsheetSession(withItems: [
      makeMenuItem("Copy", cmdChar: "C", modifiers: Self.controlNoCmd),
    ], inMenu: "Edit")

    session.updateModifierFilter([.command])
    session.query = "co"

    session.clearQuery()

    XCTAssertTrue(session.query.isEmpty)
    XCTAssertTrue(session.modifierFilter.isEmpty)
  }

  func testCommandFilterExcludesNonCommandItems() {
    let session = makeCheetsheetSession(withItems: [
      makeMenuItem("Copy", cmdChar: "C", modifiers: Self.hasCommand),
      makeMenuItem("Paste", cmdChar: "V", modifiers: Self.noCommand),
    ], inMenu: "Edit")

    session.updateModifierFilter([.command])

    let filtered = session.filteredGroups

    XCTAssertEqual(filtered[0].items.count, 1)
    XCTAssertEqual(filtered[0].items[0].title, "Copy")
  }
}

