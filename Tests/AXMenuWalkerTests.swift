//
//  AXMenuWalkerTests.swift
//  MenuetTests
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

  func testWalkBailsAtDeadline() {
    let clock = VirtualClock()
    let bars = (1...10).map { i in
      makeMenuBarItem(title: "Bar\(i)", items: [makeItem("Leaf\(i)")])
    }
    let menuBar = makeMenuBar(bars)
    injectClock(clock, delay: 0.1, into: menuBar)
    let app = FakeAXApplication(menuBar: menuBar)
    let visitor = RecordingVisitor()
    let deadline = clock.now().addingTimeInterval(0.5)

    let didComplete = AXMenuWalker(application: app, clock: clock)
      .walk(visitor: visitor, deadline: deadline)

    XCTAssertFalse(didComplete)
    XCTAssertLessThan(visitor.entered.count, bars.count)
  }

  func testWalkCompletesUnderDeadline() {
    let clock = VirtualClock()
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [makeItem("New")]),
      makeMenuBarItem(title: "Edit", items: [makeItem("Cut")]),
    ])
    // delay 0 — every read advances the clock by 0; we never approach the deadline
    injectClock(clock, delay: 0, into: menuBar)
    let app = FakeAXApplication(menuBar: menuBar)
    let visitor = RecordingVisitor()
    let deadline = clock.now().addingTimeInterval(10)

    let didComplete = AXMenuWalker(application: app, clock: clock)
      .walk(visitor: visitor, deadline: deadline)

    XCTAssertTrue(didComplete)
    XCTAssertEqual(visitor.entered, ["File", "Edit"])
    XCTAssertEqual(visitor.visited, ["New", "Cut"])
  }

  func testWalkWithoutDeadlineAlwaysCompletes() {
    let app = FakeAXApplication(menuBar: makeMenuBar([
      makeMenuBarItem(title: "File", items: [makeItem("New")]),
    ]))
    let didComplete = AXMenuWalker(application: app)
      .walk(visitor: RecordingVisitor())
    XCTAssertTrue(didComplete)
  }
}


/// Recursively wires the same VirtualClock and per-access delay into
/// every FakeAXElement reachable from `element`. Required because each
/// fake holds its own clock reference; the test needs all of them to
/// share one instance so attribute reads cumulatively advance time.
private func injectClock(
  _ clock: VirtualClock, delay: TimeInterval, into element: FakeAXElement
) {
  element.clock = clock
  element.responseDelay = delay
  for child in element.children {
    if let fake = child as? FakeAXElement {
      injectClock(clock, delay: delay, into: fake)
    }
  }
}
