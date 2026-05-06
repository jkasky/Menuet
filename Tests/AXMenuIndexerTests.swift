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


private func makeMenuBar(_ items: [FakeAXElement]) -> FakeAXElement {
  let menuBar = FakeAXElement()
  menuBar.role = .MenuBar
  menuBar.children = items
  return menuBar
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
    ])
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
    ])
    let app = FakeAXApplication(menuBar: menuBar)
    let index = MenuIndex()

    AXMenuWalker(application: app).walk(
      visitor: AXMenuIndexer(index: index, indexAppleMenu: true))

    XCTAssertEqual(index.find(query: "About").count, 1)
  }
}
