//
//  AXMenuIndexerTests.swift
//  MenuetTests
//

import OSLog
import XCTest


class MenuItemShortcutTests: XCTestCase {

  func testFromCmdChar() {
    let item = makeMenuItem("Save")
    item.stringAttributes[.MenuItemCmdChar] = "S"
    item.intAttributes[.MenuItemCmdModifiers] = 0

    let s = MenuItemShortcut.extract(from: item, logger: Logger())

    XCTAssertEqual(s.character, "S")
    XCTAssertNotNil(s.modifiers)
  }

  func testNoCharMeansNoModifiers() {
    let item = makeMenuItem("Plain")
    item.intAttributes[.MenuItemCmdModifiers] = 0

    let s = MenuItemShortcut.extract(from: item, logger: Logger())

    XCTAssertNil(s.character)
    XCTAssertNil(s.modifiers)
  }

  func testGlyphTakesPrecedenceOverCmdChar() {
    let item = makeMenuItem("Item")
    item.intAttributes[.MenuItemCmdGlyph] = KeyGlyph.Return.code
    item.stringAttributes[.MenuItemCmdChar] = "X"

    let s = MenuItemShortcut.extract(from: item, logger: Logger())

    XCTAssertEqual(s.character, KeyGlyph.Return.characters)
  }

  // The display `character` is the glyph ("↩") while `keyEquivalent` carries
  // the scalar a real Return press delivers ("\r") — the split that lets
  // `MenuItemCommand.matches` compare against actual key events.
  func testGlyphCarriesKeyEquivalent() {
    let item = makeMenuItem("Item")
    item.intAttributes[.MenuItemCmdGlyph] = KeyGlyph.Return.code

    let s = MenuItemShortcut.extract(from: item, logger: Logger())

    XCTAssertEqual(s.character, KeyGlyph.Return.characters)
    XCTAssertEqual(s.keyEquivalent, "\r")
  }

  // Printable `cmdChar` shortcuts match by `character`, so they carry no
  // separate `keyEquivalent`.
  func testCmdCharHasNoKeyEquivalent() {
    let item = makeMenuItem("Save")
    item.stringAttributes[.MenuItemCmdChar] = "S"
    item.intAttributes[.MenuItemCmdModifiers] = 0

    let s = MenuItemShortcut.extract(from: item, logger: Logger())

    XCTAssertNil(s.keyEquivalent)
  }

  // Unmapped glyph codes appear on real menu items that *also* report a
  // useful `MenuItemCmdChar` (e.g. "Emoji & Symbols" reports glyph 0x95
  // alongside char "E"). Falling back to cmdChar keeps the shortcut
  // renderable without forcing a manual KeyGlyph entry for every new
  // glyph Apple ships.
  func testFallsBackToCmdCharWhenGlyphUnrecognized() {
    let item = makeMenuItem("Item")
    item.intAttributes[.MenuItemCmdGlyph] = -1
    item.stringAttributes[.MenuItemCmdChar] = "X"
    item.intAttributes[.MenuItemCmdModifiers] = 0

    let s = MenuItemShortcut.extract(from: item, logger: Logger())

    XCTAssertEqual(s.character, "X")
    XCTAssertNotNil(s.modifiers)
  }
}


class AXMenuIndexerTests: XCTestCase {

  func testIndexesMenuItemTitleAndPath() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [makeMenuItem("New")]),
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
      makeMenuBarItem(title: "Apple", items: [makeMenuItem("About")]),
      makeMenuBarItem(title: "File",  items: [makeMenuItem("New")]),
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
      makeMenuBarItem(title: "Apple", items: [makeMenuItem("About")]),
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
      makeMenuBarItem(title: "NotApple", items: [makeMenuItem("About")]),
      makeMenuBarItem(title: "File", items: [makeMenuItem("New")]),
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
      makeMenuBarItem(title: "NotApple", items: [makeMenuItem("About")]),
      makeMenuBarItem(title: "File", items: [makeMenuItem("New")]),
    ], applePrefixed: false)
    let app = FakeAXApplication(menuBar: menuBar)
    let index = MenuIndex()

    AXMenuWalker(application: app).walk(
      visitor: AXMenuIndexer(index: index, indexAppleMenu: true))

    XCTAssertEqual(index.find(query: "About").first?.isAppleMenu, true)
    XCTAssertEqual(index.find(query: "New").first?.isAppleMenu, false)
  }
}
