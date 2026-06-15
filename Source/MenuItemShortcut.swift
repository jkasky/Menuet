//
//  MenuItemShortcut.swift
//  Menuet
//

import Foundation
import OSLog


struct MenuItemShortcut {

  let character: String?
  let modifiers: Modifiers?
  let symbolName: String?

  /// Apps occasionally publish an icon-style shortcut via `MenuItemCmdChar`
  /// (a single emoji) alongside a generic `MenuItemCmdGlyph` that doesn't
  /// describe what's drawn — e.g. Start Dictation reports
  /// `cmdGlyph=Fn (0x96)` + `cmdChar=🎤`. The glyph would otherwise win and
  /// render as the textual "fn", which is not what Apple draws. When the
  /// `cmdChar` matches one of these emoji we override with the matching SF
  /// Symbol so the chip renders the same glyph as the native menu.
  private static let cmdCharSymbolOverrides: [String: String] = [
    "🎤": "microphone",
  ]

  static func extract(from item: AX.Element, logger: Logger) -> MenuItemShortcut {
    let cmdChar: String? = try? item.get(.MenuItemCmdChar)
    var character: String?
    var symbolName: String?
    if let cmdChar, let symbol = cmdCharSymbolOverrides[cmdChar] {
      character = cmdChar
      symbolName = symbol
    } else if let glyphCode: Int = try? item.get(.MenuItemCmdGlyph) {
      character = KeyGlyph.forCode(glyphCode)?.characters
      if character == nil {
        logger.info("menu item '\(item.title)' has command with unrecognized glyph code \(glyphCode)")
      }
    }
    if character == nil {
      character = cmdChar
    }
    var modifiers: Modifiers?
    if character != nil, let raw: Int = try? item.get(.MenuItemCmdModifiers) {
      modifiers = Modifiers(axRawValue: raw)
    }
    return MenuItemShortcut(character: character, modifiers: modifiers, symbolName: symbolName)
  }
}
