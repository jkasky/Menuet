//
//  AXMenuWalkerTests.swift
//  MenuBarProTests
//

import XCTest


private class RecordingVisitor: AXMenuVisitor {
  var entered: [String] = []
  var left: [String] = []
  var visited: [String] = []

  func enterMenu(_ e: AX.Element) { entered.append(e.title) }
  func leaveMenu(_ e: AX.Element) { left.append(e.title) }
  func visitMenuItem(_ e: AX.Element) { visited.append(e.title) }
}


private func makeItem(_ title: String, role: AX.Role = .MenuItem) -> FakeAXElement {
  let item = FakeAXElement()
  item.role = role
  item.stringAttributes[.Title] = title
  return item
}


private func makeMenu(items: [FakeAXElement]) -> FakeAXElement {
  let menu = FakeAXElement()
  menu.role = .Menu
  menu.children = items
  return menu
}


private func makeMenuBarItem(title: String, items: [FakeAXElement]) -> FakeAXElement {
  let bar = FakeAXElement()
  bar.role = .MenuBarItem
  bar.stringAttributes[.Title] = title
  bar.children = [makeMenu(items: items)]
  return bar
}


private func makeMenuBar(_ items: [FakeAXElement]) -> FakeAXElement {
  let menuBar = FakeAXElement()
  menuBar.role = .MenuBar
  menuBar.children = items
  return menuBar
}


class AXMenuWalkerTests: XCTestCase {

  func testVisitOrderFlatMenu() {
    let app = FakeAXApplication(menuBar: makeMenuBar([
      makeMenuBarItem(title: "File", items: [makeItem("New"), makeItem("Open")]),
      makeMenuBarItem(title: "Edit", items: [makeItem("Cut"),  makeItem("Copy")]),
    ]))
    let visitor = RecordingVisitor()

    AXMenuWalker(application: app).walk(visitor: visitor)

    XCTAssertEqual(visitor.visited, ["New", "Open", "Cut", "Copy"])
    XCTAssertEqual(visitor.entered, ["File", "Edit"])
    XCTAssertEqual(visitor.left,    ["File", "Edit"])
  }

  func testEmptyMenuBar() {
    let app = FakeAXApplication(menuBar: nil)
    let visitor = RecordingVisitor()

    AXMenuWalker(application: app).walk(visitor: visitor)

    XCTAssertTrue(visitor.entered.isEmpty)
    XCTAssertTrue(visitor.left.isEmpty)
    XCTAssertTrue(visitor.visited.isEmpty)
  }

  func testMenuBarItemWithNoMenuSkipped() {
    let lonely = FakeAXElement()
    lonely.role = .MenuBarItem
    lonely.stringAttributes[.Title] = "Lonely"
    let app = FakeAXApplication(menuBar: makeMenuBar([
      lonely,
      makeMenuBarItem(title: "Edit", items: [makeItem("Copy")]),
    ]))
    let visitor = RecordingVisitor()

    AXMenuWalker(application: app).walk(visitor: visitor)

    XCTAssertEqual(visitor.entered, ["Edit"])
    XCTAssertEqual(visitor.visited, ["Copy"])
  }

  func testNestedSubmenu() {
    let bold = makeItem("Bold")
    let font = makeItem("Font")
    font.children = [makeMenu(items: [bold])]
    let format = makeMenuBarItem(title: "Format", items: [font])
    let app = FakeAXApplication(menuBar: makeMenuBar([format]))
    let visitor = RecordingVisitor()

    AXMenuWalker(application: app).walk(visitor: visitor)

    XCTAssertEqual(visitor.entered, ["Format", "Font"])
    XCTAssertEqual(visitor.left,    ["Font", "Format"])
    XCTAssertEqual(visitor.visited, ["Bold"])
  }
}
