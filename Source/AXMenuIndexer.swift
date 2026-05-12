//
//  AXMenuIndexer.swift
//  Menuet
//

import Foundation
import OSLog


private let logger = Logger(subsystem: "app.menuet", category: "menu")


struct MenuItemShortcut {

  let character: String?
  let modifiers: Modifiers?

  static func extract(from item: AX.Element, logger: Logger) -> MenuItemShortcut {
    var character: String?
    if let glyphCode: Int = try? item.get(.MenuItemCmdGlyph) {
      character = KeyGlyph.forCode(glyphCode)?.characters
      if character == nil {
        logger.warning("menu item '\(item.title)' has command with unrecognized glyph code \(glyphCode)")
      }
    } else {
      character = try? item.get(.MenuItemCmdChar)
    }
    var modifiers: Modifiers?
    if character != nil, let raw: Int = try? item.get(.MenuItemCmdModifiers) {
      modifiers = Modifiers(rawValue: raw)
    }
    return MenuItemShortcut(character: character, modifiers: modifiers)
  }
}


/// Tracks the walker's position in the menu tree.
///
/// At any point during a walk, the tracker carries two parallel facts about
/// the chain of ancestors from the menu bar down to the current cursor:
/// - `titles` — display titles, used to build `MenuItem.path`
/// - `positions` — each ancestor's index among its parent's children, used
///   by `AXMenuItemPath` to re-resolve a menu item by tree position when
///   the captured `AX.Element` has been invalidated
///
/// Mutations are paired with the visitor callbacks: `push` on `enterMenu`,
/// `pop` on `leaveMenu`, `recordLeaf` on `visitMenuItem`. The tracker
/// internally maintains `nextChildIndex` so siblings get sequential
/// positions without the caller doing arithmetic.
struct MenuPathTracker {

  private(set) var titles: [String] = []
  private(set) var positions: [UInt] = []
  private var nextChildIndex: UInt = 0
  private var nextChildIndexStack: [UInt] = []

  mutating func push(title: String) {
    titles.append(title)
    positions.append(nextChildIndex)
    nextChildIndexStack.append(nextChildIndex)
    nextChildIndex = 0
  }

  mutating func pop() {
    titles.removeLast()
    positions.removeLast()
    let parentSlot = nextChildIndexStack.removeLast()
    nextChildIndex = parentSlot + 1
  }

  /// Snapshots the leaf's full title path and positional path, then bumps
  /// the next-sibling cursor so the following leaf in the same parent
  /// records the correct position.
  mutating func recordLeaf(title: String) -> (titles: [String], positions: [UInt]) {
    let leafTitles = titles + [title]
    let leafPositions = positions + [nextChildIndex]
    nextChildIndex += 1
    return (leafTitles, leafPositions)
  }
}


class AXMenuIndexer: AXMenuVisitor {

  private let indexAppleMenu: Bool

  private var tracker = MenuPathTracker()
  private var index: MenuIndex

  init(index: MenuIndex, indexAppleMenu: Bool = UserDefaults.standard.searchAppleMenu) {
    self.index = index
    self.indexAppleMenu = indexAppleMenu
  }

  func enterMenu(_ menu: AX.Element) {
    tracker.push(title: menu.title)
  }

  func leaveMenu(_: AX.Element) {
    tracker.pop()
  }

  func visitMenuItem(_ item: AX.Element) {
    let title = item.title
    let (titles, positions) = tracker.recordLeaf(title: title)
    // Apple menu is always the first top-level menu of an app's menu
    // bar. Keying on position avoids depending on what AX returns for
    // the menu's title — the rendered UI is the apple glyph, and the
    // AXTitle behind it is implementation-defined.
    let isAppleMenu = positions.first == 0
    if !indexAppleMenu && isAppleMenu {
      return
    }
    let shortcut = MenuItemShortcut.extract(from: item, logger: logger)
    let delegate = AXMenuItemDelegate(item, path: positions)
    let menuItem = MenuItem(
      title: title,
      command: MenuItemCommand(
        character: shortcut.character ?? "",
        modifiers: shortcut.modifiers ?? Modifiers.noCommand,
        delegate: delegate),
      path: titles,
      isAppleMenu: isAppleMenu,
      delegate: delegate)
    index.add(menuItem)
  }
}
