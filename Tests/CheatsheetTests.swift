//
//  CheatsheetTests.swift
//  MenuBarProTests
//

import XCTest


private func makeItem(
  _ title: String,
  cmdChar: String? = nil,
  modifiers: Int? = nil
) -> FakeAXElement {
  let item = FakeAXElement()
  item.role = .MenuItem
  item.stringAttributes[.Title] = title
  item.boolAttributes[.Enabled] = true
  if let cmdChar = cmdChar {
    item.stringAttributes[.MenuItemCmdChar] = cmdChar
    item.intAttributes[.MenuItemCmdModifiers] = modifiers ?? 0
  }
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
        makeItem("New", cmdChar: "N"),
        makeItem("Open Recent"),
        makeItem("Save", cmdChar: "S"),
      ]),
    ])

    let titles = buildIndex(menuBar).itemsWithShortcuts().map(\.title)

    XCTAssertEqual(titles, ["New", "Save"])
  }

  func testItemsWithShortcutsEmptyWhenNoneHaveShortcuts() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "Help", items: [makeItem("About")]),
    ])

    XCTAssertTrue(buildIndex(menuBar).itemsWithShortcuts().isEmpty)
  }
}


class CheatsheetGroupingTests: XCTestCase {

  func testGroupsByTopLevelMenuPreservingOrder() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [
        makeItem("New",  cmdChar: "N"),
        makeItem("Save", cmdChar: "S"),
      ]),
      makeMenuBarItem(title: "Edit", items: [
        makeItem("Copy",  cmdChar: "C"),
        makeItem("Paste", cmdChar: "V"),
      ]),
    ])
    let items = buildIndex(menuBar).itemsWithShortcuts()

    let groups = SearchManager.groupForCheatsheet(items)

    XCTAssertEqual(groups.map(\.menu), ["File", "Edit"])
    XCTAssertEqual(groups[0].items.map(\.title), ["New", "Save"])
    XCTAssertEqual(groups[1].items.map(\.title), ["Copy", "Paste"])
  }

  func testExcludesAppleMenu() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "Apple", items: [makeItem("Force Quit", cmdChar: "Q", modifiers: 1)]),
      makeMenuBarItem(title: "File",  items: [makeItem("New",        cmdChar: "N")]),
    ])
    // indexAppleMenu: true ensures Apple items reach the index — grouping
    // should still drop them.
    let items = buildIndex(menuBar, indexAppleMenu: true).itemsWithShortcuts()

    let groups = SearchManager.groupForCheatsheet(items)

    XCTAssertEqual(groups.map(\.menu), ["File"])
  }

  func testEmptyInputProducesNoGroups() {
    XCTAssertTrue(SearchManager.groupForCheatsheet([]).isEmpty)
  }
}
