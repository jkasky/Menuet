//
//  Menu.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 2018-12-09.
//  Copyright © 2018 Codjax. All rights reserved.
//

import Foundation


struct ModifierKeyChar {
  static let Command = "\u{2318}"
  static let Control = "\u{2303}"
  static let Option = "\u{2325}"
  static let Shift = "\u{21E7}"
}


struct Modifiers: OptionSet {
  let rawValue: Int
  
  var stringValue: String {
    var value = ""
    if self.contains(.control) {
      value.append(ModifierKeyChar.Control)
    }
    if self.contains(.option) {
      value.append(ModifierKeyChar.Option)
    }
    if self.contains(.shift) {
      value.append(ModifierKeyChar.Shift)
    }
    if !self.contains(.noCommand) {
      value.append(ModifierKeyChar.Command)
    }
    return value
  }
  
  static let shift = Modifiers(rawValue: 1)
  static let option = Modifiers(rawValue: 2)
  static let control = Modifiers(rawValue: 4)
  static let noCommand = Modifiers(rawValue: 8)
}


struct MenuItemCommand {
  
  let character: String
  let modifiers: Modifiers
  let stringValue: String
  
  init(character: String, modifiers: Modifiers) {
    self.character = character
    self.modifiers = modifiers
    self.stringValue = modifiers.stringValue + character
  }
}


struct MenuItem {
  
  let title: String
  let command: MenuItemCommand
  
  init(title: String, command: MenuItemCommand, enabled: Bool) {
    self.title = title
    self.command = command
  }
}


class MenuIndex {
  
  private var trie = Trie<MenuItem>()
  
  func add(item: MenuItem, path: String) {
    trie.insert(label: path, value: item)
  }
  
  func find(query: String) -> [MenuItem] {
    return trie.find(sequence: query)
  }
}


class AXMenuIndexer: AXMenuVisitor {
  
  private var path: [String] = []
  private var index: MenuIndex
  
  init(index: MenuIndex) {
    self.index = index
  }
  
  func enterMenu(_ menu: AX.Element) {
    if let title:String = menu.get(.Title) {
      path.append(title)
    }
  }
  
  func leaveMenu(_: AX.Element) {
    _ = path.popLast()
  }
  
  func visitMenuItem(_ item: AX.Element) {
    if let title:String = item.get(.Title) {
      let menuItem = MenuItem(
        title: title,
        command: MenuItemCommand(
          character: item.get(.MenuItemCmdChar) ?? "",
          modifiers: Modifiers(rawValue: item.get(.MenuItemCmdModifiers) ?? 0)),
        enabled: item.get(.Enabled) ?? false)
      index.add(item: menuItem, path: path.joined(separator: " > "))
    }
  }
}
