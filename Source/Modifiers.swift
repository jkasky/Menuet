//
//  Modifiers.swift
//  Menuet
//

import AppKit
import Foundation


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
