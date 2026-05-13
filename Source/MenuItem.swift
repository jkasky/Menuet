//
//  MenuItem.swift
//  Menuet
//

import AppKit
import Foundation
import OSLog


private let logger = Logger(subsystem: "app.menuet", category: "menu")


/// All stored properties are immutable; the optional delegate is only
/// invoked via `perform()` which is always called on main (AX actions
/// require main thread). Treat as Sendable so it can flow through
/// @Sendable closure parameters at SwiftUI environment boundaries.
final class MenuItemCommand: @unchecked Sendable {

  let character: String
  let modifiers: Modifiers
  let stringValue: String
  let delegate: AXMenuItemDelegate?

  init(character: String, modifiers: Modifiers,
       delegate: AXMenuItemDelegate? = nil) {
    self.character = character
    self.modifiers = modifiers
    self.stringValue = modifiers.joinWith(character)
    self.delegate = delegate
  }

  func perform() {
    delegate?.press()
  }

  /// Polls the delegate's `isEnabled` at `pollInterval` and presses the
  /// moment it reports enabled, falling through to press anyway after
  /// `timeout`. Used by the panels to wait for the target app to
  /// re-validate first-responder-dependent menu items (Cut/Copy/etc.)
  /// after we resign main and the target reactivates — NSMenu
  /// validation is lazy, so the press needs to happen *after* the
  /// target's runloop has processed the activation event. Polling the
  /// actual enabled signal beats a fixed defer.
  ///
  /// Each `isEnabled` read is itself bounded by the system-wide AX
  /// messaging timeout, so a hung target can't stall the poll loop.
  func performWhenEnabled(
    timeout: TimeInterval = 1.0,
    pollInterval: TimeInterval = 0.05
  ) {
    let deadline = Date().addingTimeInterval(timeout)
    pollUntilEnabled(deadline: deadline, pollInterval: pollInterval)
  }

  private func pollUntilEnabled(deadline: Date, pollInterval: TimeInterval) {
    if delegate?.isEnabled == true || Date() >= deadline {
      perform()
      return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + pollInterval) { [self] in
      pollUntilEnabled(deadline: deadline, pollInterval: pollInterval)
    }
  }

  /// True when this command is the keyboard equivalent of `event` — the
  /// canonical "did the user just type my shortcut?" check used by both
  /// panels' `performKeyEquivalent`.
  ///
  /// Uses `charactersIgnoringModifiers` when present and non-empty so
  /// dead-key combinations (⌥E → "´") still match the underlying letter,
  /// and falls back to `characters` only when the modifier-stripped form
  /// is missing or empty. Empty `character` (items without a shortcut)
  /// never match.
  func matches(_ event: NSEvent) -> Bool {
    guard !character.isEmpty else { return false }
    guard let target = Self.eventCharacter(event) else { return false }
    return character.uppercased() == target
        && modifiers == event.modifierFlags
  }

  private static func eventCharacter(_ event: NSEvent) -> String? {
    if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
      return chars.uppercased()
    }
    if let chars = event.characters, !chars.isEmpty {
      return chars.uppercased()
    }
    return nil
  }
}


class MenuItem: CustomDebugStringConvertible, Equatable, Identifiable {

  static func == (left: MenuItem, right: MenuItem) -> Bool {
    return left.id == right.id
  }

  let id: UUID
  let title: String
  let command: MenuItemCommand
  let path: [String]
  let enabled: Bool
  /// True when this item lives under the Apple (system) menu — i.e. the
  /// first top-level menu of the menu bar. Determined by position rather
  /// than by matching a string against `AXTitle`: AX's title for the
  /// Apple menu is implementation-defined (the rendered UI is the apple
  /// glyph, not text), so position is the only stable signal.
  let isAppleMenu: Bool

  var debugDescription: String {
    return "MenuItem<path:\(path.joined(separator: "/"))>"
  }

  var pathDescription: String {
    if isAppleMenu {
      return ([KeyGlyph.Apple.characters] + path[1...]).joined(separator: " > ")
    } else {
      return path.joined(separator: " > ")
    }
  }

  /// VoiceOver-friendly path: spells out "Apple" instead of the glyph so
  /// screen readers don't announce it as an unknown symbol.
  var accessibilityPath: [String] {
    isAppleMenu ? ["Apple"] + Array(path.dropFirst()) : path
  }

  init(title: String, command: MenuItemCommand, path: [String],
       isAppleMenu: Bool, delegate: AXMenuItemDelegate) {
    self.id = UUID()
    self.title = title
    self.command = command
    self.path = path
    self.enabled = delegate.isEnabled
    self.isAppleMenu = isAppleMenu
  }
}


class AXMenuItemDelegate {

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
      // Initial press threw — typically because the captured element
      // was invalidated between the walk and the press. Try resolving
      // by index path. Both perform throws and resolution failures
      // need to surface: AXElement.perform already logs its own
      // failure, so we only need to log the unresolved-path case.
      let path = AXMenuItemPath(application: element.application, path: indexPath)
      guard let resolved = path.get() else {
        logger.error("press: could not resolve menu item by path \(self.indexPath, privacy: .public) after initial press failed")
        return
      }
      try? resolved.perform(action: .Press)
    }
  }
}
