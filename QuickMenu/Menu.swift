//
//  Menu.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 2018-12-09.
//  Copyright © 2018 Codjax. All rights reserved.
//

import Foundation


/**
 * A coded symbol (i.e. glyph) that represents a non-printable key.
 */
struct KeyGlyph {
    
  // Modifiers & Special Keys
  static let Alt           = KeyGlyph(0x8B, "\u{2387}")  //  ⎇
  static let Apple         = KeyGlyph(0x14, "\u{F8FF}")  //  
  static let AppleOutlined = KeyGlyph(0x6C, "\u{F8FF}")  //  
  static let Blank         = KeyGlyph(0x61, "\u{2423}")  //  ␣
  static let CapsLock      = KeyGlyph(0x63, "\u{21EA}")  //  ⇪
  static let Clear         = KeyGlyph(0x1C, "\u{2327}")  //  ⌧
  static let Command       = KeyGlyph(0x11, "\u{2318}")  //  ⌘
  static let ContextMenu   = KeyGlyph(0x6D, "\u{F803}")  //  
  static let Control       = KeyGlyph(0x06, "\u{2303}")  //  ⌃
  static let ControlISO    = KeyGlyph(0x8A, "\u{2388}")  //  ⎈
  static let Delete        = KeyGlyph(0x17, "\u{232B}")  //  ⌫
  static let DeleteRTL     = KeyGlyph(0x0A, "\u{2326}")  //  ⌦
  static let Down          = KeyGlyph(0x6A, "\u{2193}")  //  ↓
  static let Eject         = KeyGlyph(0x8C, "\u{23CF}")  //  ⏏
  static let End           = KeyGlyph(0x69, "\u{2198}")  //  ↘
  static let Enter         = KeyGlyph(0x04, "\u{2324}")  //  ⌤
  static let Escape        = KeyGlyph(0x1B, "\u{238B}")  //  ⎋
  static let Help          = KeyGlyph(0x67, "\u{003F}")  //  ?⃝
  static let Home          = KeyGlyph(0x66, "\u{2196}")  //  ↖
  static let Left          = KeyGlyph(0x64, "\u{2190}")  //  ←
  static let Option        = KeyGlyph(0x07, "\u{2325}")  //  ⌥q
  static let PageDown      = KeyGlyph(0x6B, "\u{21DF}")  //  ⇟
  static let PageUp        = KeyGlyph(0x62, "\u{21DE}")  //  ⇞
  static let Power         = KeyGlyph(0x6E, "\u{2758}")  //  ❘⃝
  static let Return        = KeyGlyph(0x0B, "\u{21A9}")  //  ↩
  static let ReturnRTL     = KeyGlyph(0x0C, "\u{21AA}")  //  ↪
  static let Right         = KeyGlyph(0x65, "\u{2192}")  //  →
  static let Shift         = KeyGlyph(0x05, "\u{21E7}")  //  ⇧
  static let Space         = KeyGlyph(0x09, "\u{2423}")  //  ␣
  static let Tab           = KeyGlyph(0x02, "\u{21E5}")  //  ⇥
  static let TabRTL        = KeyGlyph(0x03, "\u{21E4}")  //  ⇤
  static let Up            = KeyGlyph(0x68, "\u{2191}")  //  ↑
  
  // Function Keys
  static let F1            = KeyGlyph(0x6F, "F1")
  static let F2            = KeyGlyph(0x70, "F2")
  static let F3            = KeyGlyph(0x71, "F3")
  static let F4            = KeyGlyph(0x72, "F4")
  static let F5            = KeyGlyph(0x73, "F5")
  static let F6            = KeyGlyph(0x74, "F6")
  static let F7            = KeyGlyph(0x75, "F7")
  static let F8            = KeyGlyph(0x76, "F8")
  static let F9            = KeyGlyph(0x77, "F9")
  static let F10           = KeyGlyph(0x78, "F10")
  static let F11           = KeyGlyph(0x79, "F11")
  static let F12           = KeyGlyph(0x7A, "F12")
  static let F13           = KeyGlyph(0x87, "F13")
  static let F14           = KeyGlyph(0x88, "F14")
  static let F15           = KeyGlyph(0x89, "F15")
  
  /**
   * Holds map of virtual codes to associated KeyGlyph.
   */
  private static var codeMap: [Int: KeyGlyph] = [:]
  
  /**
   * Returns KeyGlyph for given virtual code.
   */
  static func forCode(_ code: Int) -> KeyGlyph? {
    return codeMap[code]
  }
  
  /**
   * Adds new KeyGlyph to code map.
   */
  fileprivate static func mapCode(_ glyph: KeyGlyph) {
    codeMap[glyph.code] = glyph
  }
  
  let code: Int
  let characters: String
  
  init(_ code: Int, _ characters: String) {
    self.code = code
    self.characters = characters
  }
}


// Enumerate all the static constants to force initialization so that the
// lookup by code map is built. If there is a better way to do this in Swift,
// figure it out.
func initializeMenuResources() {
  let glyphs: [KeyGlyph] = [
    .Alt,
    .Apple,
    .AppleOutlined,
    .Blank,
    .CapsLock,
    .Clear,
    .Command,
    .ContextMenu,
    .Control,
    .ControlISO,
    .Delete,
    .DeleteRTL,
    .Eject,
    .End,
    .Enter,
    .Escape,
    .Help,
    .Home,
    .Left,
    .Option,
    .PageDown,
    .PageUp,
    .Power,
    .Return,
    .ReturnRTL,
    .Right,
    .Shift,
    .Space,
    .Tab,
    .TabRTL,
    .Up,
    .F1,
    .F2,
    .F3,
    .F4,
    .F5,
    .F6,
    .F7,
    .F8,
    .F9,
    .F10,
    .F11,
    .F12,
    .F13,
    .F14,
    .F15,
  ]
  for g in glyphs {
    KeyGlyph.mapCode(g)
  }
}


struct Modifiers: OptionSet {
  let rawValue: Int
  
  var stringValue: String {
    var value = ""
    if self.contains(.control) {
      value.append(KeyGlyph.Control.characters)
    }
    if self.contains(.option) {
      value.append(KeyGlyph.Option.characters)
    }
    if self.contains(.shift) {
      value.append(KeyGlyph.Shift.characters)
    }
    if !self.contains(.noCommand) {
      value.append(KeyGlyph.Command.characters)
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
      path.append(title)
      defer { _ = path.popLast() }
      var character: String?
      if let glyphCode: Int = item.get(.MenuItemCmdGlyph) {
        character = KeyGlyph.forCode(glyphCode)?.characters
      } else {
        character = item.get(.MenuItemCmdChar)
      }
      var modifiers: Modifiers?
      if let commandModifiers: Int = item.get(.MenuItemCmdModifiers) {
        modifiers = Modifiers(rawValue: commandModifiers)
      }
      let menuItem = MenuItem(
        title: title,
        command: MenuItemCommand(
          character: character ?? "",
          modifiers: modifiers ?? Modifiers.noCommand),
        enabled: item.get(.Enabled) ?? false)
      let menuItemPath = path.joined(separator: " > ")
      index.add(item: menuItem, path: menuItemPath)
    }
  }
}
