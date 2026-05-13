//
//  Modifiers.swift
//  Menuet
//

import AppKit
import Foundation


/// Modifier-key set for a menu shortcut. Every bit is positive: `.command`
/// means "Command is part of the shortcut". AX itself encodes the Command
/// bit inverted (its bit 8 is set when Command is *absent*); the inversion
/// is handled at the boundary by `init(axRawValue:)` so readers can think
/// in plain terms.
struct Modifiers: OptionSet {
  let rawValue: Int

  init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Translate AX's raw `AXMenuItemCmdModifiers` int (bit 8 set = no
  /// Command) into the positive encoding used elsewhere.
  init(axRawValue: Int) {
    var raw = 0
    if (axRawValue & 1)  != 0 { raw |= Modifiers.shift.rawValue }
    if (axRawValue & 2)  != 0 { raw |= Modifiers.option.rawValue }
    if (axRawValue & 4)  != 0 { raw |= Modifiers.control.rawValue }
    if (axRawValue & 8)  == 0 { raw |= Modifiers.command.rawValue }
    if (axRawValue & 16) != 0 { raw |= Modifiers.function.rawValue }
    self.init(rawValue: raw)
  }

  init(eventFlags: NSEvent.ModifierFlags) {
    var raw = 0
    if eventFlags.contains(.shift)    { raw |= Modifiers.shift.rawValue }
    if eventFlags.contains(.control)  { raw |= Modifiers.control.rawValue }
    if eventFlags.contains(.option)   { raw |= Modifiers.option.rawValue }
    if eventFlags.contains(.command)  { raw |= Modifiers.command.rawValue }
    if eventFlags.contains(.function) { raw |= Modifiers.function.rawValue }
    self.init(rawValue: raw)
  }

  var stringValue: String {
    var value = ""
    if contains(.control) { value.append(KeyGlyph.Control.characters) }
    if contains(.option)  { value.append(KeyGlyph.Option.characters) }
    if contains(.shift)   { value.append(KeyGlyph.Shift.characters) }
    if contains(.command) { value.append(KeyGlyph.Command.characters) }
    if contains(.function) {
      // Globe is visually wider than ⌃⌥⇧⌘, so flank it with thin spaces to
      // match the breathing room macOS gives it in its own menu rendering
      // (e.g. "⌃ 🌐 F" rather than "⌃🌐F").
      value.append("\u{2009}")
      value.append(KeyGlyph.Globe.characters)
      value.append("\u{2009}")
    }
    return value
  }

  func joinWith(_ character: String) -> String {
    return stringValue + character
  }

  // Item must hold every non-Command bit the filter requires; Command
  // must match exactly. Extra modifier bits on the item are tolerated.
  func containsFilter(_ filter: NSEvent.ModifierFlags) -> Bool {
    if filter.isEmpty { return true }
    let required = Modifiers(eventFlags: filter)
    let nonCommand: Modifiers = [.shift, .control, .option, .function]
    return isSuperset(of: required.intersection(nonCommand))
        && contains(.command) == required.contains(.command)
  }

  static func ==(lhs: Modifiers, rhs: NSEvent.ModifierFlags) -> Bool {
    return lhs == Modifiers(eventFlags: rhs)
  }

  static let shift    = Modifiers(rawValue: 1 << 0)
  static let option   = Modifiers(rawValue: 1 << 1)
  static let control  = Modifiers(rawValue: 1 << 2)
  static let command  = Modifiers(rawValue: 1 << 3)
  static let function = Modifiers(rawValue: 1 << 4)
}
