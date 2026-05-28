//
//  MenuItem.swift
//  Menuet
//

import AppKit
import Foundation
import OSLog
import SwiftUI


/// Readiness signal injected into `MenuItemCommand.performWhenReady` so
/// the poll loop knows when the target app has finished restoring its
/// previously-key window after the panel resigned key. Protocol-fronted
/// so tests can flip the signal manually without booting a real
/// `NSRunningApplication` or AX bridge.
///
/// `hasFocusedWindow` is the cross-process mirror of `NSApp.keyWindow`:
/// `NSRunningApplication.isActive` flips true at the WindowServer level
/// well before the target's runloop services activation and re-promotes
/// a key window, which is what menu items like Window > "Move to ‹Display›"
/// depend on. Polling `AXFocusedWindow` waits for that runloop tick.
///
/// Refines `Sendable` because the poll loop hops between main-queue
/// dispatch ticks under strict-concurrency.
protocol MenuItemTarget: Sendable {
  var hasFocusedWindow: Bool { get }
  /// Human-readable identifier for logs (bundle id, etc.). Optional —
  /// fakes can return an empty string.
  var debugDescription: String { get }
}


/// Press surface for `MenuItemCommand`. Lets tests substitute a recording
/// fake without standing up an `AX.Element`. `AXMenuItemDelegate` is the
/// production conformer.
protocol MenuItemPressTarget: AnyObject {
  var isEnabled: Bool { get }
  func press()
}


/// Production `MenuItemTarget` that bundles the running-application
/// activation flag with an AX query for the target's focused window.
/// `isActive` is checked first as a cheap short-circuit so we avoid a
/// cross-process AX hop while the activation hasn't even started.
///
/// `@unchecked Sendable` because `AX.Application` isn't `Sendable`-bound,
/// but all production access happens on the main queue (the poll loop
/// only hops between main-queue dispatch ticks; AX APIs are
/// main-thread-only).
struct ActivationTarget: MenuItemTarget, @unchecked Sendable {
  let runningApp: NSRunningApplication
  let axApp: AX.Application

  var hasFocusedWindow: Bool {
    guard runningApp.isActive else { return false }
    let focused: AX.Element? = try? axApp.topElement.get(.FocusedWindow)
    return focused != nil
  }

  var debugDescription: String {
    return runningApp.bundleIdentifier ?? "pid:\(runningApp.processIdentifier)"
  }
}


private let logger = Logger(subsystem: "app.menuet", category: "menu")


/// All stored properties are immutable; the optional delegate is only
/// invoked via `perform()` which is always called on main (AX actions
/// require main thread). Treat as Sendable so it can flow through
/// @Sendable closure parameters at SwiftUI environment boundaries.
final class MenuItemCommand: @unchecked Sendable {

  let character: String
  let modifiers: Modifiers
  let stringValue: String
  /// SF Symbol name when the shortcut's character is best rendered as a
  /// system symbol rather than its raw unicode form — e.g. Start
  /// Dictation reports `cmdChar=🎤` which we render as the
  /// `microphone` SF Symbol to match Apple's own menu drawing. `nil` for
  /// the common text-only case; `character` retains the original unicode
  /// so accessibility, search, and matching code paths keep working with
  /// a plain `String`.
  let symbolName: String?
  let delegate: MenuItemPressTarget?

  /// SwiftUI rendering of the shortcut: modifier glyphs followed by
  /// either the SF Symbol image (when `symbolName` is set) or the
  /// textual `character`. Consumed by `ShortcutChip`.
  var displayText: Text {
    let prefix = Text(modifiers.stringValue)
    if let symbolName {
      return prefix + Text(Image(systemName: symbolName))
    }
    return prefix + Text(character)
  }

  init(character: String, modifiers: Modifiers,
       symbolName: String? = nil,
       delegate: MenuItemPressTarget? = nil) {
    self.character = character
    self.modifiers = modifiers
    self.stringValue = modifiers.joinWith(character)
    self.symbolName = symbolName
    self.delegate = delegate
  }

  func perform() {
    delegate?.press()
  }

  /// Polls two readiness signals at `pollInterval` and presses the
  /// moment both report ready, falling through to press anyway after
  /// `timeout`:
  ///
  /// 1. `target.hasFocusedWindow` — the cross-process activation requested
  ///    by `FloatingActionPanel.dismiss` is async, and the target's
  ///    `NSApp.keyWindow` is only re-promoted several runloop ticks after
  ///    `NSRunningApplication.isActive` flips true. Window-menu items
  ///    that read `NSApp.keyWindow` (e.g. "Move to ‹Display›") silently
  ///    no-op if the AX press races that promotion, so we wait for the
  ///    AX mirror (`AXFocusedWindow`) to be non-nil.
  /// 2. `delegate.isEnabled` — first-responder-dependent items
  ///    (Cut/Copy/etc.) report disabled while the target's key window
  ///    is gone; NSMenu validation is lazy, so we wait until validation
  ///    has re-run after activation.
  ///
  /// Each AX read is bounded by the system-wide messaging timeout, so
  /// a hung target can't stall the poll loop.
  func performWhenReady(
    target: MenuItemTarget?,
    timeout: TimeInterval = 1.0,
    pollInterval: TimeInterval = 0.05
  ) {
    let start = Date()
    let deadline = start.addingTimeInterval(timeout)
    logger.debug("performWhenReady start command=\(self.stringValue, privacy: .public) target=\(target?.debugDescription ?? "<none>", privacy: .public) hasFocusedWindow=\(target?.hasFocusedWindow ?? true) isEnabled=\(self.delegate?.isEnabled == true)")
    pollUntilReady(target: target, start: start, deadline: deadline, pollInterval: pollInterval)
  }

  private func pollUntilReady(
    target: MenuItemTarget?,
    start: Date,
    deadline: Date,
    pollInterval: TimeInterval
  ) {
    let focused = target?.hasFocusedWindow ?? true
    let enabled = delegate?.isEnabled == true
    let now = Date()
    let elapsedMs = Int(now.timeIntervalSince(start) * 1000)
    if focused && enabled {
      logger.debug("performWhenReady press command=\(self.stringValue, privacy: .public) reason=ready elapsed=\(elapsedMs)ms")
      perform()
      return
    }
    if now >= deadline {
      logger.debug("performWhenReady press command=\(self.stringValue, privacy: .public) reason=deadline elapsed=\(elapsedMs)ms hasFocusedWindow=\(focused) isEnabled=\(enabled)")
      perform()
      return
    }
    logger.debug("performWhenReady tick command=\(self.stringValue, privacy: .public) elapsed=\(elapsedMs)ms hasFocusedWindow=\(focused) isEnabled=\(enabled)")
    DispatchQueue.main.asyncAfter(deadline: .now() + pollInterval) { [self] in
      pollUntilReady(target: target, start: start, deadline: deadline, pollInterval: pollInterval)
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


struct MenuItem: Hashable, Sendable, Identifiable, CustomDebugStringConvertible {

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
       enabled: Bool, isAppleMenu: Bool) {
    self.id = UUID()
    self.title = title
    self.command = command
    self.path = path
    self.enabled = enabled
    self.isAppleMenu = isAppleMenu
  }

  // `MenuItemCommand` is a class with a non-Hashable `AXMenuItemDelegate?`,
  // so Hashable/Equatable can't be synthesized. Compare by the user-visible
  // content of the command (character + modifiers) and skip the delegate —
  // two walks of the same menu produce equal items even though they hold
  // fresh delegate instances.
  static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
    lhs.title == rhs.title
      && lhs.path == rhs.path
      && lhs.enabled == rhs.enabled
      && lhs.isAppleMenu == rhs.isAppleMenu
      && lhs.command.character == rhs.command.character
      && lhs.command.modifiers == rhs.command.modifiers
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(title)
    hasher.combine(path)
    hasher.combine(enabled)
    hasher.combine(isAppleMenu)
    hasher.combine(command.character)
    hasher.combine(command.modifiers.rawValue)
  }
}


class AXMenuItemDelegate: MenuItemPressTarget {

  private let element: AX.Element
  private let indexPath: [UInt]
  private let title: String

  /// Live `.Enabled` check used by `performWhenReady`'s poll loop to
  /// decide whether the menu item is currently pressable. Re-resolves
  /// the element rather than reading the one captured at walk time:
  /// dynamic Window-menu entries injected by `_NSWindowsMenuUpdater`
  /// (e.g. Window > Center, Move to ‹Display›) are torn out when the
  /// menu closes, so the cached `element` would report `.Enabled = false`
  /// indefinitely and stall the poll until its deadline.
  ///
  /// Skips the AXShowMenu step that `press()` does: at the 50ms poll
  /// cadence, opening the parent menu every tick would visibly flash
  /// it. When the item isn't currently materialised, report ready and
  /// let `press()`'s resolution dance handle materialisation.
  var isEnabled: Bool {
    guard let leaf = findByPathThenTitle() else {
      return true
    }
    return (try? leaf.get(.Enabled)) ?? false
  }

  init(_ element: AX.Element, path: [UInt], title: String) {
    self.element = element
    self.indexPath = path
    self.title = title
  }

  func press() {
    // Resolution dance for dynamic menus.
    //
    // The Window menu in AppKit apps is mutated when the menu opens:
    // `_NSWindowsMenuUpdater` inserts entries like "Move to ‹Display›"
    // in `menuNeedsUpdate:`, and tears them back out when the menu
    // closes. Our walker observes those entries (AX queries trigger
    // menuNeedsUpdate while the app is frontmost), captures both the
    // *index path* and the *title*, but by the time the user picks a
    // result the menu has closed and the dynamic entries are gone.
    // Re-resolving by path alone then lands on a different sibling
    // (in Calendar, `[5,12]` points at "Move to Built-in Retina
    // Display" while the menu is open and at "Calendar" the window-
    // switcher once it closes). `AXPress` on that wrong item returns
    // success and silently no-ops the user's intent.
    //
    // Strategy:
    //   1. Resolve by path (`leaf` whose title matches what we captured)
    //      or scan parent siblings by title (handles index drift when
    //      *other* dynamic siblings disappeared). Invisible — works for
    //      static menus (Cut/Copy/...).
    //   2. If the item is genuinely absent, open every ancestor menu in
    //      the path via `AXPress`, which fires AppKit's
    //      `menuNeedsUpdate:` and re-materialises dynamic items. Then
    //      retry the path-then-title resolution. AppKit closes the
    //      menu automatically when our final `AXPress` lands on the
    //      leaf.
    //   3. Give up and log.
    guard let resolved = resolveTarget() else {
      logger.error("press unresolved path=\(self.indexPath, privacy: .public) title=\(self.title, privacy: .public)")
      return
    }
    try? resolved.element.setMessagingTimeout(1.0)
    do {
      try resolved.element.perform(action: .Press)
      logger.debug("press succeeded path=\(self.indexPath, privacy: .public) via=\(resolved.via, privacy: .public)")
    } catch {
      logger.error("press failed path=\(self.indexPath, privacy: .public) via=\(resolved.via, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }
  }

  private struct Resolved {
    let element: AX.Element
    let via: String  // log tag identifying which strategy matched
  }

  private func resolveTarget() -> Resolved? {
    if let leaf = findByPathThenTitle() {
      return Resolved(element: leaf, via: "static")
    }
    openAncestorMenus()
    if let leaf = findByPathThenTitle() {
      return Resolved(element: leaf, via: "showmenu")
    }
    return nil
  }

  private func findByPathThenTitle() -> AX.Element? {
    let path = AXMenuItemPath(application: element.application, path: indexPath)
    if let leaf = path.get(), (try? leaf.get(.Title) as String) == title {
      return leaf
    }
    if let siblings = parentSiblings() {
      return siblings.first(where: { (try? $0.get(.Title) as String) == title })
    }
    return nil
  }

  /// Children of the menu that *contains* the leaf — the sibling set
  /// we'd scan for a title match. The "parent" is whatever path[:-1]
  /// resolves to: the menu bar for top-level items, a MenuBarItem (its
  /// `childAt(0)` is the menu) for first-level items, or a MenuItem-
  /// with-submenu for deeper items.
  private func parentSiblings() -> [AX.Element]? {
    guard !indexPath.isEmpty else { return nil }
    let parentPath = AXMenuItemPath(
      application: element.application, path: Array(indexPath.dropLast()))
    guard let parent = parentPath.get() else { return nil }
    if parent.isA(.MenuBar) {
      return parent.findAll(.MenuBarItem)
    }
    if parent.isA(.MenuBarItem) || parent.isA(.MenuItem) {
      guard let menu = parent.childAt(0) else { return nil }
      return menu.findAll(.MenuItem)
    }
    return nil
  }

  /// Walks the path from the menu bar down to (but not including) the
  /// leaf, sending `AXPress` to every MenuBarItem / MenuItem-with-
  /// submenu along the way. `AXPress` is the action AppKit honors to
  /// open a menu bar item's menu or a parent menu item's submenu
  /// (`AXShowMenu` is for popup buttons and is rejected here with
  /// `AXError.failure`). Best-effort — failures are logged and we
  /// continue, since a partial open may still be enough for the
  /// re-resolution to succeed.
  private func openAncestorMenus() {
    var current: AX.Element? = try? element.application.topElement.get(.MenuBar)
    for (depth, i) in indexPath.enumerated() {
      guard let el = current else { return }
      if el.isA(.MenuBar) {
        current = el.childAt(i)
        continue
      }
      if el.isA(.MenuBarItem) || el.isA(.MenuItem) {
        // We're about to descend into this ancestor's menu via
        // childAt(0).childAt(i). Open it first so dynamic children
        // materialise and the menu enters tracking mode (some action
        // dispatch paths in AppKit only fire during active tracking).
        do {
          try el.perform(action: .Press)
        } catch {
          logger.debug("openAncestorMenus Press failed depth=\(depth): \(error.localizedDescription, privacy: .public)")
        }
        current = el.childAt(0)?.childAt(i)
        continue
      }
      return
    }
  }
}
