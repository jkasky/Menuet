//
//  AXMenuIndexerTests.swift
//  MenuetTests
//

import OSLog
import XCTest


private func makeItem(_ title: String, enabled: Bool = true) -> FakeAXElement {
  let item = FakeAXElement()
  item.role = .MenuItem
  item.stringAttributes[.Title] = title
  item.boolAttributes[.Enabled] = enabled
  return item
}


private func makeMenuBarItem(title: String, items: [FakeAXElement]) -> FakeAXElement {
  let menu = FakeAXElement()
  menu.role = .Menu
  menu.children = items

  let bar = FakeAXElement()
  bar.role = .MenuBarItem
  bar.stringAttributes[.Title] = title
  bar.children = [menu]
  return bar
}


/// Real macOS menu bars always start with the system Apple menu at
/// position 0. The indexer identifies the Apple menu by position
/// (locale-independent), so fixtures that want their menus to be treated
/// as non-Apple must mirror that layout. Default is `applePrefixed: true`
/// so individual tests don't have to remember; tests that explicitly
/// exercise the Apple-menu filter pass `applePrefixed: false`.
private func makeMenuBar(_ items: [FakeAXElement], applePrefixed: Bool = true) -> FakeAXElement {
  let menuBar = FakeAXElement()
  menuBar.role = .MenuBar
  menuBar.children = applePrefixed ? [makeAppleStub()] + items : items
  return menuBar
}

private func makeAppleStub() -> FakeAXElement {
  return makeMenuBarItem(title: "Apple", items: [])
}


class MenuItemShortcutTests: XCTestCase {

  func testFromCmdChar() {
    let item = makeItem("Save")
    item.stringAttributes[.MenuItemCmdChar] = "S"
    item.intAttributes[.MenuItemCmdModifiers] = 0

    let s = MenuItemShortcut.extract(from: item, logger: Logger())

    XCTAssertEqual(s.character, "S")
    XCTAssertNotNil(s.modifiers)
  }

  func testNoCharMeansNoModifiers() {
    let item = makeItem("Plain")
    item.intAttributes[.MenuItemCmdModifiers] = 0

    let s = MenuItemShortcut.extract(from: item, logger: Logger())

    XCTAssertNil(s.character)
    XCTAssertNil(s.modifiers)
  }

  func testGlyphTakesPrecedenceOverCmdChar() {
    let item = makeItem("Item")
    // pick any glyph code KeyGlyph recognizes; we only assert the precedence
    // (cmdChar is ignored when a glyph code is present).
    item.intAttributes[.MenuItemCmdGlyph] = -1   // unrecognized glyph
    item.stringAttributes[.MenuItemCmdChar] = "X"

    let s = MenuItemShortcut.extract(from: item, logger: Logger())

    // unrecognized glyph code → character is nil, and cmdChar is NOT consulted
    XCTAssertNil(s.character)
  }
}


class AXMenuIndexerTests: XCTestCase {

  func testIndexesMenuItemTitleAndPath() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [makeItem("New")]),
    ])
    let app = FakeAXApplication(menuBar: menuBar)
    let index = MenuIndex()

    AXMenuWalker(application: app).walk(
      visitor: AXMenuIndexer(index: index, indexAppleMenu: false))

    let results = index.find(query: "New")
    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.title, "New")
    XCTAssertEqual(results.first?.path, ["File", "New"])
  }

  func testSkipsAppleMenuWhenFlagOff() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "Apple", items: [makeItem("About")]),
      makeMenuBarItem(title: "File",  items: [makeItem("New")]),
    ], applePrefixed: false)
    let app = FakeAXApplication(menuBar: menuBar)
    let index = MenuIndex()

    AXMenuWalker(application: app).walk(
      visitor: AXMenuIndexer(index: index, indexAppleMenu: false))

    XCTAssertTrue(index.find(query: "About").isEmpty)
    XCTAssertEqual(index.find(query: "New").count, 1)
  }

  func testIncludesAppleMenuWhenFlagOn() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "Apple", items: [makeItem("About")]),
    ], applePrefixed: false)
    let app = FakeAXApplication(menuBar: menuBar)
    let index = MenuIndex()

    AXMenuWalker(application: app).walk(
      visitor: AXMenuIndexer(index: index, indexAppleMenu: true))

    XCTAssertEqual(index.find(query: "About").count, 1)
  }

  // The Apple menu must be identified by position, not by string-matching
  // its AXTitle: AX's title for the system menu is implementation-defined
  // (the visible UI is the apple glyph, not text). Use a deliberately
  // unrelated title at position 0 to verify the indexer doesn't fall back
  // to a string check.
  func testSkipsAppleMenuByPositionRegardlessOfTitle() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "NotApple", items: [makeItem("About")]),
      makeMenuBarItem(title: "File", items: [makeItem("New")]),
    ], applePrefixed: false)
    let app = FakeAXApplication(menuBar: menuBar)
    let index = MenuIndex()

    AXMenuWalker(application: app).walk(
      visitor: AXMenuIndexer(index: index, indexAppleMenu: false))

    XCTAssertTrue(index.find(query: "About").isEmpty)
    XCTAssertEqual(index.find(query: "New").count, 1)
  }

  func testIsAppleMenuFlagSetByPosition() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "NotApple", items: [makeItem("About")]),
      makeMenuBarItem(title: "File", items: [makeItem("New")]),
    ], applePrefixed: false)
    let app = FakeAXApplication(menuBar: menuBar)
    let index = MenuIndex()

    AXMenuWalker(application: app).walk(
      visitor: AXMenuIndexer(index: index, indexAppleMenu: true))

    XCTAssertEqual(index.find(query: "About").first?.isAppleMenu, true)
    XCTAssertEqual(index.find(query: "New").first?.isAppleMenu, false)
  }
}
