//
//  AXVisitor.swift
//  Menuet
//
//

import Foundation
import OSLog


private let logger = Logger(subsystem: "app.menuet", category: "ax.menu")


/// Receives a depth-first traversal of an application's menu tree.
///
/// Callback ordering for any menu (the menu bar's children or a submenu):
/// 1. `enterMenu` fires for the menu's owning element (a `MenuBarItem` for
///    a top-level menu, or a `MenuItem` whose role contains a `Menu` for a
///    submenu) before any of its descendants are visited.
/// 2. The menu's children are walked in order: leaves call `visitMenuItem`;
///    items that contain a submenu recurse via `enterMenu` / `leaveMenu`.
/// 3. `leaveMenu` fires after every descendant has been visited.
///
/// A leaf item (no submenu) receives only `visitMenuItem` — never
/// `enterMenu` / `leaveMenu`.
protocol AXMenuVisitor {

  func enterMenu(_: AX.Element)

  func leaveMenu(_: AX.Element)

  func visitMenuItem(_: AX.Element)

}


class AXMenuWalker {

  private let application: AX.Application
  private let clock: WallClock
  private var deadline: Date?
  private var didComplete: Bool = true

  init(application: AX.Application, clock: WallClock = SystemClock()) {
    self.application = application
    self.clock = clock
  }

  /// Walks the application's menu tree, calling visitor methods in
  /// depth-first order (see `AXMenuVisitor`). When `deadline` is set, the
  /// walker checks it between sibling iterations and bails early when
  /// exceeded. Items already visited stay in the visitor's accumulated
  /// state — partial work is not rolled back.
  ///
  /// - returns: `true` if the walk visited every menu before `deadline`,
  ///   `false` if it bailed early. Always `true` when `deadline == nil`.
  @discardableResult
  func walk(visitor: AXMenuVisitor, deadline: Date? = nil) -> Bool {
    self.deadline = deadline
    self.didComplete = true
    guard let menuBar = application.menuBar else { return true }
    for menuBarItem in menuBar.findAll(.MenuBarItem) {
      if hasExpired() { break }
      guard let menu = menuBarItem.find(.Menu) else { continue }
      visitor.enterMenu(menuBarItem)
      walkMenu(menu: menu, visitor: visitor)
      visitor.leaveMenu(menuBarItem)
    }
    return didComplete
  }

  private func walkMenu(menu: AX.Element, visitor: AXMenuVisitor) {
    for item in menu.findAll(.MenuItem) {
      if hasExpired() { return }
      if let submenu = item.find(.Menu) {
        visitor.enterMenu(item)
        walkMenu(menu: submenu, visitor: visitor)
        visitor.leaveMenu(item)
      } else {
        visitor.visitMenuItem(item)
      }
    }
  }

  private func hasExpired() -> Bool {
    guard let deadline = deadline else { return false }
    if clock.now() >= deadline {
      didComplete = false
      return true
    }
    return false
  }
}


class AXMenuItemPath {

  let application: AX.Application
  let path: [UInt]

  init(application: AX.Application, path: [UInt]) {
    self.application = application
    self.path = path
  }

  func get() -> AX.Element? {
    var nextElement: AX.Element? = try? application.topElement.get(.MenuBar)
    for i in path {
      guard let currentElement = nextElement else {
        break
      }
      if currentElement.isA(.MenuBar) {
        nextElement = currentElement.childAt(i)
        continue
      }
      if currentElement.isA(.MenuBarItem) {
        nextElement = currentElement.childAt(0)?.childAt(i)
        continue
      }
      if currentElement.isA(.MenuItem) {
        nextElement = currentElement.childAt(0)?.childAt(i)
        continue
      }
    }
    return nextElement
  }
}


