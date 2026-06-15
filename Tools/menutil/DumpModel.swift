//
//  DumpModel.swift
//  menutil
//
//  Codable models for the menu dump. Optional fields are encoded with the
//  synthesized `encodeIfPresent`, so nil values (no subrole, no shortcut,
//  diagnostics off, flat output) are simply omitted from JSON.
//

import Foundation


/// The running app a walk targeted.
struct AppInfo: Codable {
  let pid: Int32
  let bundleId: String?
  let name: String?
  let frontmost: Bool
}


/// A menu item's keyboard shortcut, rendered the same way Menuet renders it.
struct ShortcutInfo: Codable {
  /// The shortcut's base character or glyph (e.g. "B", "↩").
  let key: String
  /// Modifier names, outer→inner: control, option, shift, command, function.
  let modifiers: [String]
  /// Fully rendered chip, e.g. "⌘B".
  let display: String
}


/// One node in the menu tree. Leaves carry `children == nil`; menus carry a
/// (possibly empty) `children` array. In flat output `children` is stripped.
struct MenuNode: Codable {
  let title: String
  /// Display-title path from the menu bar down to this node, inclusive.
  let path: [String]
  /// Each ancestor's index among its siblings, parallel to `path`. Mirrors
  /// `AXMenuItemPath`/`MenuPathTracker` positions used elsewhere.
  let positionPath: [Int]
  /// Number of levels below the menu bar (top-level menu == 1).
  let depth: Int
  let enabled: Bool
  let role: String
  let subrole: String?
  let hasSubmenu: Bool
  let shortcut: ShortcutInfo?

  // Diagnostics (only populated with --diagnostics).
  let actions: [String]?
  let attributes: [String: String]?
  /// Subset of `attributes` whose values are writable
  /// (`AXUIElementIsAttributeSettable`). Distinguishes interactive items from
  /// inert ones in a way the attribute *names* can't.
  var settableAttributes: [String]? = nil
  /// Parameterized-attribute namespace (separate from `attributes`).
  var parameterizedAttributes: [String]? = nil
  /// Human-readable description per action name.
  var actionDescriptions: [String: String]? = nil

  // Tree children (only populated for tree output).
  var children: [MenuNode]?
}


/// Top-level JSON envelope for a walk.
struct DumpEnvelope: Codable {
  let app: AppInfo
  /// False when the walker bailed at its deadline before visiting everything.
  let complete: Bool
  let items: [MenuNode]
}
