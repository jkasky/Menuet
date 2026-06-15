//
//  MenuDumpVisitorTests.swift
//  MenuetTests
//
//  Covers the CLI's tree-building visitor and the Render filter/flatten
//  helpers, reusing the shared FakeAXElement / MenuBarFixtures.
//

import XCTest


// MARK: - Local fixtures

/// A MenuItem that owns a submenu (MenuBarFixtures only builds leaves and
/// top-level bar items). Mirrors `makeMenuBarItem` but with a MenuItem role.
private func makeSubmenu(_ title: String, items: [FakeAXElement]) -> FakeAXElement {
  let menu = FakeAXElement()
  menu.role = .Menu
  menu.children = items

  let item = FakeAXElement()
  item.role = .MenuItem
  item.stringAttributes[.Title] = title
  item.boolAttributes[.Enabled] = true
  item.children = [menu]
  return item
}

private func walk(_ menuBar: FakeAXElement, _ visitor: MenuDumpVisitor) {
  let app = FakeAXApplication(menuBar: menuBar)
  AXMenuWalker(application: app).walk(visitor: visitor)
}


// MARK: - Visitor

class MenuDumpVisitorTests: XCTestCase {

  func testBuildsTreeWithPathsPositionsAndDepth() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [
        makeMenuItem("New"),
        makeMenuItem("Open"),
      ]),
    ])  // applePrefixed: true → Apple at position 0, File at position 1
    let visitor = MenuDumpVisitor(diagnostics: false, includeApple: false, depthCap: .max)

    walk(menuBar, visitor)

    XCTAssertEqual(visitor.roots.count, 1)
    let file = visitor.roots[0]
    XCTAssertEqual(file.title, "File")
    XCTAssertEqual(file.path, ["File"])
    XCTAssertEqual(file.positionPath, [1])
    XCTAssertEqual(file.depth, 1)
    XCTAssertTrue(file.hasSubmenu)

    XCTAssertEqual(file.children?.count, 2)
    let new = file.children?[0]
    XCTAssertEqual(new?.title, "New")
    XCTAssertEqual(new?.path, ["File", "New"])
    XCTAssertEqual(new?.positionPath, [1, 0])
    XCTAssertEqual(new?.depth, 2)
    XCTAssertFalse(new?.hasSubmenu ?? true)
    XCTAssertEqual(file.children?[1].positionPath, [1, 1])
  }

  func testSkipsAppleMenuByDefault() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [makeMenuItem("New")]),
    ])
    let visitor = MenuDumpVisitor(diagnostics: false, includeApple: false, depthCap: .max)

    walk(menuBar, visitor)

    XCTAssertEqual(visitor.roots.map(\.title), ["File"])
  }

  func testIncludeAppleAddsTheSystemMenu() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [makeMenuItem("New")]),
    ])
    let visitor = MenuDumpVisitor(diagnostics: false, includeApple: true, depthCap: .max)

    walk(menuBar, visitor)

    XCTAssertEqual(visitor.roots.map(\.title), ["Apple", "File"])
    XCTAssertEqual(visitor.roots[0].positionPath, [0])
  }

  func testNestedSubmenu() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [
        makeMenuItem("New"),
        makeSubmenu("Share", items: [makeMenuItem("AirDrop")]),
      ]),
    ])
    let visitor = MenuDumpVisitor(diagnostics: false, includeApple: false, depthCap: .max)

    walk(menuBar, visitor)

    let share = visitor.roots[0].children?[1]
    XCTAssertEqual(share?.title, "Share")
    XCTAssertTrue(share?.hasSubmenu ?? false)
    let airdrop = share?.children?[0]
    XCTAssertEqual(airdrop?.path, ["File", "Share", "AirDrop"])
    XCTAssertEqual(airdrop?.positionPath, [1, 1, 0])
    XCTAssertEqual(airdrop?.depth, 3)
  }

  func testDepthCapDropsDeeperItems() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [makeMenuItem("New")]),
    ])
    let visitor = MenuDumpVisitor(diagnostics: false, includeApple: false, depthCap: 1)

    walk(menuBar, visitor)

    XCTAssertEqual(visitor.roots.count, 1)
    XCTAssertEqual(visitor.roots[0].children?.count, 0)
  }

  func testCapturesShortcut() {
    let menuBar = makeMenuBar([
      makeMenuBarItem(title: "File", items: [
        makeMenuItem("Save", cmdChar: "S", modifiers: 0),  // raw 0 → ⌘ only
        makeMenuItem("Plain"),
      ]),
    ])
    let visitor = MenuDumpVisitor(diagnostics: false, includeApple: false, depthCap: .max)

    walk(menuBar, visitor)

    let save = visitor.roots[0].children?[0]
    XCTAssertEqual(save?.shortcut?.key, "S")
    XCTAssertEqual(save?.shortcut?.modifiers, ["command"])
    XCTAssertEqual(save?.shortcut?.display, "\u{2318}S")
    XCTAssertNil(visitor.roots[0].children?[1].shortcut)
  }

  func testDiagnosticsCaptureActionsAndAttributes() {
    let item = makeMenuItem("Build")
    item.actionNamesList = ["AXPress"]
    item.attributeNamesList = ["AXRole", "AXTitle"]
    item.attributeDescriptions = ["AXRole": "AXMenuItem", "AXTitle": "Build"]
    let menuBar = makeMenuBar([makeMenuBarItem(title: "Product", items: [item])])

    let on = MenuDumpVisitor(diagnostics: true, includeApple: false, depthCap: .max)
    walk(menuBar, on)
    let leaf = on.roots[0].children?[0]
    XCTAssertEqual(leaf?.actions, ["AXPress"])
    XCTAssertEqual(leaf?.attributes?["AXRole"], "AXMenuItem")

    let off = MenuDumpVisitor(diagnostics: false, includeApple: false, depthCap: .max)
    walk(menuBar, off)
    XCTAssertNil(off.roots[0].children?[0].actions)
    XCTAssertNil(off.roots[0].children?[0].attributes)
  }
}


// MARK: - Render

class RenderTests: XCTestCase {

  private func leaf(_ title: String) -> MenuNode {
    MenuNode(
      title: title, path: [title], positionPath: [0], depth: 1, enabled: true,
      role: "AXMenuItem", subrole: nil, hasSubmenu: false, shortcut: nil,
      actions: nil, attributes: nil, children: nil)
  }

  func testFilteredRanksPrefixHighestAndExcludesNonMatches() {
    let items = [leaf("Newsletter"), leaf("Window"), leaf("New")]

    let results = Render.filtered(items, query: "new")

    XCTAssertEqual(results.map(\.title), ["New", "Newsletter"])  // Window drops out
  }

  func testFilteredEmptyForNoMatches() {
    XCTAssertTrue(Render.filtered([leaf("Copy")], query: "xyz").isEmpty)
  }

  func testFlattenStripsChildrenDepthFirst() {
    var parent = leaf("File")
    parent.children = [leaf("New")]

    let flat = Render.flatten([parent])

    XCTAssertEqual(flat.map(\.title), ["File", "New"])
    XCTAssertTrue(flat.allSatisfy { $0.children == nil })
  }
}
