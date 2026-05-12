//
//  MenuBarFixtures.swift
//  MenuetTests
//
//  Shared FakeAXElement builders for tests that walk a synthetic menu
//  bar (CheatsheetTests, AXMenuIndexerTests). AXMenuWalkerTests use a
//  different shape and keep their own helpers.
//

import Foundation


/// Builds a leaf menu item with optional command shortcut. `enabled`
/// defaults to true so callers don't have to set it.
func makeMenuItem(
  _ title: String,
  enabled: Bool = true,
  cmdChar: String? = nil,
  modifiers: Int? = nil
) -> FakeAXElement {
  let item = FakeAXElement()
  item.role = .MenuItem
  item.stringAttributes[.Title] = title
  item.boolAttributes[.Enabled] = enabled
  if let cmdChar = cmdChar {
    item.stringAttributes[.MenuItemCmdChar] = cmdChar
    item.intAttributes[.MenuItemCmdModifiers] = modifiers ?? 0
  }
  return item
}


/// Wraps `items` in a Menu inside a top-level MenuBarItem with the
/// given title.
func makeMenuBarItem(title: String, items: [FakeAXElement]) -> FakeAXElement {
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
/// (locale-independent), so fixtures that want their menus to be
/// treated as non-Apple must mirror that layout. Default is
/// `applePrefixed: true` so individual tests don't have to remember;
/// tests that explicitly exercise the Apple-menu filter pass
/// `applePrefixed: false`.
func makeMenuBar(_ items: [FakeAXElement], applePrefixed: Bool = true) -> FakeAXElement {
  let menuBar = FakeAXElement()
  menuBar.role = .MenuBar
  menuBar.children = applePrefixed ? [makeAppleStub()] + items : items
  return menuBar
}


func makeAppleStub() -> FakeAXElement {
  return makeMenuBarItem(title: "Apple", items: [])
}
