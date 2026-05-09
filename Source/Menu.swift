//
//  Menu.swift
//  Menuet
//
//

import AppKit
import Foundation
import OSLog


/**
 * A coded symbol (i.e. glyph) that represents a non-printable key.
 */
struct KeyGlyph {

  // Modifier Keys
  static let Alt           = KeyGlyph(0x8B, "\u{2387}")  //  ⎇
  static let Control       = KeyGlyph(0x06, "\u{2303}")  //  ⌃
  // U+FE0E variation selector forces text-style (monochrome) rendering of
  // the globe codepoint, matching how macOS draws the Fn/Globe modifier in
  // its own menus instead of the colored emoji presentation.
  static let Globe         = KeyGlyph(0x98, "\u{1F310}\u{FE0E}") //  🌐︎
  static let Option        = KeyGlyph(0x07, "\u{2325}")  //  ⌥
  static let Shift         = KeyGlyph(0x05, "\u{21E7}")  //  ⇧

  // Special Keys & Glyphs
  static let Apple              = KeyGlyph(0x14, "\u{F8FF}")  //  
  static let AppleOutlined      = KeyGlyph(0x6C, "\u{F8FF}")  //  
  static let Blank              = KeyGlyph(0x61, "\u{2423}")  //  ␣
  static let CapsLock           = KeyGlyph(0x63, "\u{21EA}")  //  ⇪
  static let Checkmark          = KeyGlyph(0x12, "\u{2713}")  //  ✓
  static let Clear              = KeyGlyph(0x1C, "\u{2327}")  //  ⌧
  static let Command            = KeyGlyph(0x11, "\u{2318}")  //  ⌘
  static let ContextMenu        = KeyGlyph(0x6D, "\u{F803}")  //  
  static let ControlISO         = KeyGlyph(0x8A, "\u{2388}")  //  ⎈
  static let Delete             = KeyGlyph(0x17, "\u{232B}")  //  ⌫
  static let DeleteRTL          = KeyGlyph(0x0A, "\u{2326}")  //  ⌦
  static let Diamond            = KeyGlyph(0x13, "\u{25C6}")  //  ◆
  static let Down               = KeyGlyph(0x6A, "\u{2193}")  //  ↓
  static let DownDashed         = KeyGlyph(0x10, "\u{21E3}")  //  ⇣
  static let Eject              = KeyGlyph(0x8C, "\u{23CF}")  //  ⏏
  static let End                = KeyGlyph(0x69, "\u{2198}")  //  ↘
  static let Enter              = KeyGlyph(0x04, "\u{2324}")  //  ⌤
  static let Escape             = KeyGlyph(0x1B, "\u{238B}")  //  ⎋
  static let Help               = KeyGlyph(0x67, "\u{003F}")  //  ?⃝
  static let Home               = KeyGlyph(0x66, "\u{2196}")  //  ↖
  static let Left               = KeyGlyph(0x64, "\u{2190}")  //  ←
  static let LeftDashed         = KeyGlyph(0x18, "\u{21E0}")  //  ⇠
  static let LeftQuoteJapanese  = KeyGlyph(0x1D, "\u{300C}")  //  「
  static let PageDown           = KeyGlyph(0x6B, "\u{21DF}")  //  ⇟
  static let PageUp             = KeyGlyph(0x62, "\u{21DE}")  //  ⇞
  static let ParagraphKorean    = KeyGlyph(0x15, "\u{00B6}")  //  ¶
  static let Pencil             = KeyGlyph(0x0F, "\u{270F}")  //  ✏
  static let Power              = KeyGlyph(0x6E, "\u{23FB}")  //  ⏻
  static let Return             = KeyGlyph(0x0B, "\u{21A9}")  //  ↩
  static let ReturnNonmarking   = KeyGlyph(0x0D, "\u{21A9}")  //  ↩
  static let ReturnRTL          = KeyGlyph(0x0C, "\u{21AA}")  //  ↪
  static let Right              = KeyGlyph(0x65, "\u{2192}")  //  →
  static let RightDashed        = KeyGlyph(0x1A, "\u{21E2}")  //  ⇢
  static let RightQuoteJapanese = KeyGlyph(0x1E, "\u{300D}")  //  」
  static let Space              = KeyGlyph(0x09, "\u{2423}")  //  ␣
  static let Tab                = KeyGlyph(0x02, "\u{21E5}")  //  ⇥
  static let TabRTL             = KeyGlyph(0x03, "\u{21E4}")  //  ⇤
  static let Trademark          = KeyGlyph(0x1F, "\u{2122}")  //  ™
  static let Up                 = KeyGlyph(0x68, "\u{2191}")  //  ↑
  static let UpDashed           = KeyGlyph(0x19, "\u{21E1}")  //  ⇡
  
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
  static let Fn            = KeyGlyph(0x96, "fn")
  
  /// Map of virtual key codes to glyphs. Built once at type-load time
  /// from the static constants above; immutable thereafter.
  private static let codeMap: [Int: KeyGlyph] = {
    let glyphs: [KeyGlyph] = [
      .Alt, .Apple, .AppleOutlined, .Blank, .CapsLock, .Checkmark, .Clear,
      .Command, .ContextMenu, .Control, .ControlISO, .Delete, .DeleteRTL,
      .Diamond, .Down, .DownDashed, .Eject, .End, .Enter, .Escape, .Globe,
      .Help, .Home, .Left, .LeftDashed, .LeftQuoteJapanese, .Option,
      .PageDown, .PageUp, .ParagraphKorean, .Pencil, .Power, .Return,
      .ReturnNonmarking, .ReturnRTL, .Right, .RightDashed,
      .RightQuoteJapanese, .Shift, .Space, .Tab, .TabRTL, .Trademark, .Up,
      .UpDashed, .F1, .F2, .F3, .F4, .F5, .F6, .F7, .F8, .F9, .F10, .F11,
      .F12, .F13, .F14, .F15, .Fn,
    ]
    return Dictionary(uniqueKeysWithValues: glyphs.map { ($0.code, $0) })
  }()

  /// Returns the KeyGlyph for the given virtual key code, if any.
  static func forCode(_ code: Int) -> KeyGlyph? {
    return codeMap[code]
  }

  let code: Int
  let characters: String

  init(_ code: Int, _ characters: String) {
    self.code = code
    self.characters = characters
  }
}


extension KeyGlyph: CustomStringConvertible {
  var description: String {
    return characters
  }
}

extension DefaultStringInterpolation {
  mutating func appendInterpolation(_ value: KeyGlyph) {
    appendInterpolation(value.description)
  }
}


struct Modifiers: OptionSet {
  let rawValue: Int

  init(rawValue: Int) {
    self.rawValue = rawValue
  }

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
    // Globe is visually wider than ⌃⌥⇧⌘, so flank it with thin spaces to
    // match the breathing room macOS gives it in its own menu rendering
    // (e.g. "⌃ 🌐 F" rather than "⌃🌐F").
    if self.contains(.function) {
      value.append("\u{2009}")
      value.append(KeyGlyph.Globe.characters)
      value.append("\u{2009}")
    }
    return value
  }

  func joinWith(_ character: String) -> String {
    if self.rawValue > 0 {
      return self.stringValue + character
    } else if self.rawValue == 0 && character.count > 0 {
      return self.stringValue + character
    }
    return character
  }

  // Item must hold every bit the filter requires; .command must match
  // exactly (filter has cmd ⇔ item lacks .noCommand). Extra modifier bits
  // on the item are tolerated.
  func containsFilter(_ filter: NSEvent.ModifierFlags) -> Bool {
    if filter.isEmpty { return true }
    let required = Modifiers(eventFlags: filter)
    let positive: Modifiers = [.shift, .control, .option, .function]
    return self.isSuperset(of: required.intersection(positive))
        && self.contains(.noCommand) == required.contains(.noCommand)
  }

  init(eventFlags: NSEvent.ModifierFlags) {
    var raw = 0
    if eventFlags.contains(.shift) { raw |= Modifiers.shift.rawValue }
    if eventFlags.contains(.control) { raw |= Modifiers.control.rawValue }
    if eventFlags.contains(.option) { raw |= Modifiers.option.rawValue }
    if eventFlags.contains(.function) { raw |= Modifiers.function.rawValue }
    if !eventFlags.contains(.command) { raw |= Modifiers.noCommand.rawValue }
    self.init(rawValue: raw)
  }

  static func ==(lhs: Modifiers, rhs: NSEvent.ModifierFlags) -> Bool {
    if lhs.contains(.control) != rhs.contains(.control) {
      return false
    }
    if lhs.contains(.option) != rhs.contains(.option) {
      return false
    }
    if lhs.contains(.shift) != rhs.contains(.shift) {
      return false
    }
    if !lhs.contains(.noCommand) != rhs.contains(.command) {
      return false
    }
    if lhs.contains(.function) != rhs.contains(.function) {
      return false
    }
    return true
  }

  static let shift = Modifiers(rawValue: 1)
  static let option = Modifiers(rawValue: 2)
  static let control = Modifiers(rawValue: 4)
  static let noCommand = Modifiers(rawValue: 8)
  static let function = Modifiers(rawValue: 16)
}


/// All stored properties are immutable; the optional delegate is only
/// invoked via `perform()` which is always called on main (AX actions
/// require main thread). Treat as Sendable so it can flow through
/// @Sendable closure parameters at SwiftUI environment boundaries.
final class MenuItemCommand: @unchecked Sendable {

  let character: String
  let modifiers: Modifiers
  let stringValue: String
  let delegate: MenuItemDelegate?

  init(character: String, modifiers: Modifiers,
       delegate: MenuItemDelegate? = nil) {
    self.character = character
    self.modifiers = modifiers
    self.stringValue = modifiers.joinWith(character)
    self.delegate = delegate
  }

  func perform() {
    delegate?.press()
  }
}


protocol MenuItemDelegate {
  
  /**
   * Returns true if menu item is enabled.
   */
  var isEnabled: Bool { get }
  
  /**
   * Performs the press action on the menu item.
   */
  func press()
}


class MenuItem: CustomDebugStringConvertible, Equatable, Identifiable {

  static let appleMenuTitle = "Apple"

  static func == (left: MenuItem, right: MenuItem) -> Bool {
    return left.id == right.id
  }

  let id: UUID
  let title: String
  let command: MenuItemCommand
  let path: [String]
  let enabled: Bool

  var debugDescription: String {
    return "MenuItem<path:\(path.joined(separator: "/"))>"
  }

  var pathDescription: String {
    if path[0] == MenuItem.appleMenuTitle {
      return ([KeyGlyph.Apple.characters] + path[1...]).joined(separator: " > ")
    } else {
      return path.joined(separator: " > ")
    }
  }

  private let delegate: MenuItemDelegate
  
  init(title: String, command: MenuItemCommand, path: [String],
       delegate:MenuItemDelegate) {
    self.id = UUID()
    self.title = title
    self.command = command
    self.path = path
    self.enabled = delegate.isEnabled
    self.delegate = delegate
  }
}


class MenuIndex {

  private var items: [MenuItem] = []

  var size: Int {
    return items.count
  }

  func add(item: MenuItem, path: String) {
    items.append(item)
  }

  func itemsWithShortcuts() -> [MenuItem] {
    return items.filter { !$0.command.character.isEmpty }
  }

  func find(query: String) -> [MenuItem] {
    guard !query.isEmpty else { return [] }
    let caseSensitive = UserDefaults.standard.searchCaseSensitive
    let showDisabled = UserDefaults.standard.showDisabledItems

    var scored: [(MenuItem, Int)] = []
    scored.reserveCapacity(items.count)
    for item in items {
      guard !item.title.isEmpty else { continue }
      guard showDisabled || item.enabled else { continue }
      guard let match = FuzzyMatch.score(
        query: query, candidate: item.title, caseSensitive: caseSensitive)
      else { continue }
      let pathBonus = max(0, 10 - item.path.count)
      scored.append((item, match.score + pathBonus))
    }
    return scored.sorted { $0.1 > $1.1 }.map { $0.0 }
  }
}


class AXMenuItemDelegate: MenuItemDelegate {
  
  private let element: AX.Element
  private let indexPath: [UInt]
  
  var isEnabled: Bool {
    return (try? element.get(.Enabled)) ?? false
  }
  
  init(_ element: AX.Element, path: [UInt]) {
    self.element = element
    self.indexPath = path
  }
  
  func press() {
    try? element.setMessagingTimeout(1.0)
    do {
      try element.perform(action: .Press)
      return
    } catch {
      let path = AXMenuItemPath(application: element.application, path: indexPath)
      guard let element = path.get() else {
        return
      }
      try? element.perform(action: AX.Action.Press)
    }
  }
}


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


class AXMenuIndexer: AXMenuVisitor {

  private let indexAppleMenu: Bool
  private let logger: Logger = Logger()

  private var path: [String] = []
  private var indexPath: [UInt] = []
  private var index: MenuIndex

  init(index: MenuIndex, indexAppleMenu: Bool = UserDefaults.standard.searchAppleMenu) {
    self.index = index
    self.indexAppleMenu = indexAppleMenu
  }

  func enterMenu(_ menu: AX.Element) {
    if let title: String = try? menu.get(.Title) {
      path.append(title)
      indexPath.append(0)
    }
  }

  func leaveMenu(_: AX.Element) {
    _ = path.popLast()
    _ = indexPath.popLast()
    if !indexPath.isEmpty {
      indexPath[indexPath.endIndex.advanced(by: -1)] += 1
    }
  }

  func visitMenuItem(_ item: AX.Element) {
    let title = item.title
    path.append(title)
    if indexPath.count < path.count {
      indexPath.append(0)
    }
    defer {
      _ = path.popLast()
      indexPath[indexPath.endIndex.advanced(by: -1)] += 1
    }
    if !indexAppleMenu && path[0] == MenuItem.appleMenuTitle {
      return
    }
    let shortcut = MenuItemShortcut.extract(from: item, logger: logger)
    let delegate = AXMenuItemDelegate(item, path: indexPath)
    let menuItem = MenuItem(
      title: title,
      command: MenuItemCommand(
        character: shortcut.character ?? "",
        modifiers: shortcut.modifiers ?? Modifiers.noCommand,
        delegate: delegate),
      path: path,
      delegate: delegate)
    index.add(item: menuItem, path: path.joined(separator: " > "))
  }
}
