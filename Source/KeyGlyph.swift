//
//  KeyGlyph.swift
//  Menuet
//

import AppKit
import Foundation


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
  static let Apple              = KeyGlyph(0x14, "\u{F8FF}")  //
  static let AppleOutlined      = KeyGlyph(0x6C, "\u{F8FF}")  //
  static let Blank              = KeyGlyph(0x61, "\u{2423}")  //  ␣
  static let CapsLock           = KeyGlyph(0x63, "\u{21EA}")  //  ⇪
  static let Checkmark          = KeyGlyph(0x12, "\u{2713}")  //  ✓
  static let Clear              = KeyGlyph(0x1C, "\u{2327}")  //  ⌧
  static let Command            = KeyGlyph(0x11, "\u{2318}")  //  ⌘
  static let ContextMenu        = KeyGlyph(0x6D, "\u{F803}")  //
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
      .Alt,
      .Apple,
      .AppleOutlined,
      .Blank,
      .CapsLock,
      .Checkmark,
      .Clear,
      .Command,
      .ContextMenu,
      .Control,
      .ControlISO,
      .Delete,
      .DeleteRTL,
      .Diamond,
      .Down,
      .DownDashed,
      .Eject,
      .End,
      .Enter,
      .Escape,
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
      .Fn,
      .Globe,
      .Help,
      .Home,
      .Left,
      .LeftDashed,
      .LeftQuoteJapanese,
      .Option,
      .PageDown,
      .PageUp,
      .ParagraphKorean,
      .Pencil,
      .Power,
      .Return,
      .ReturnNonmarking,
      .ReturnRTL,
      .Right,
      .RightDashed,
      .RightQuoteJapanese,
      .Shift,
      .Space,
      .Tab,
      .TabRTL,
      .Trademark,
      .Up,
      .UpDashed,
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
