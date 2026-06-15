//
//  MenuDumpVisitor.swift
//  menutil
//
//  An AXMenuVisitor that reconstructs the menu tree as `MenuNode`s while the
//  walker traverses it. Position/title bookkeeping mirrors the app's
//  `MenuPathTracker`; the CLI keeps its own copy because that type lives in
//  AXMenuIndexer.swift (SwiftUI-bound, not compiled into this target).
//

import Foundation
import OSLog


private let logger = Logger(subsystem: "app.menuet.ax", category: "dump")


final class MenuDumpVisitor: AXMenuVisitor {

  /// Top-level menus, populated as the walk completes. Each carries its
  /// subtree via `children`.
  private(set) var roots: [MenuNode] = []

  private let diagnostics: Bool
  private let includeApple: Bool
  private let depthCap: Int

  /// Parallel title/position stacks (see `MenuPathTracker`).
  private var titles: [String] = []
  private var positions: [Int] = []
  private var nextChildIndex = 0
  private var nextChildIndexStack: [Int] = []

  /// One frame per open menu; `children` accumulates as we walk it.
  private struct Frame {
    let node: MenuNode      // metadata captured at enterMenu (children nil)
    var children: [MenuNode] = []
    let included: Bool      // false when pruned by depth/Apple-menu filters
  }
  private var frames: [Frame] = []

  init(diagnostics: Bool, includeApple: Bool, depthCap: Int) {
    self.diagnostics = diagnostics
    self.includeApple = includeApple
    self.depthCap = depthCap
  }

  // MARK: - AXMenuVisitor

  func enterMenu(_ element: AX.Element) {
    let title = element.title
    let path = titles + [title]
    let positionPath = positions + [nextChildIndex]
    let depth = path.count
    let included = shouldInclude(positionPath: positionPath, depth: depth)
    let node = makeNode(
      element, title: title, path: path, positionPath: positionPath,
      depth: depth, hasSubmenu: true, captureDiagnostics: included)
    frames.append(Frame(node: node, included: included))

    // push
    titles.append(title)
    positions.append(nextChildIndex)
    nextChildIndexStack.append(nextChildIndex)
    nextChildIndex = 0
  }

  func leaveMenu(_ element: AX.Element) {
    // pop
    titles.removeLast()
    positions.removeLast()
    let parentSlot = nextChildIndexStack.removeLast()
    nextChildIndex = parentSlot + 1

    let frame = frames.removeLast()
    guard frame.included else { return }
    var node = frame.node
    node.children = frame.children
    emit(node)
  }

  func visitMenuItem(_ element: AX.Element) {
    let title = element.title
    let path = titles + [title]
    let positionPath = positions + [nextChildIndex]
    let depth = path.count
    nextChildIndex += 1
    guard shouldInclude(positionPath: positionPath, depth: depth) else { return }
    let node = makeNode(
      element, title: title, path: path, positionPath: positionPath,
      depth: depth, hasSubmenu: false, captureDiagnostics: true)
    emit(node)
  }

  // MARK: - Building

  /// Append a finished node to its parent frame, or to `roots` at top level.
  private func emit(_ node: MenuNode) {
    if frames.isEmpty {
      roots.append(node)
    } else {
      frames[frames.count - 1].children.append(node)
    }
  }

  /// Apple menu is the menu bar's first top-level item (position 0); skipped
  /// unless requested, matching `AXMenuIndexer`. Depth cap drops anything
  /// deeper than requested.
  private func shouldInclude(positionPath: [Int], depth: Int) -> Bool {
    if depth > depthCap { return false }
    if !includeApple, positionPath.first == 0 { return false }
    return true
  }

  private func makeNode(
    _ element: AX.Element, title: String, path: [String],
    positionPath: [Int], depth: Int, hasSubmenu: Bool,
    captureDiagnostics: Bool
  ) -> MenuNode {
    let role = (try? element.get(.Role) as String) ?? ""
    let subrole: String? = try? element.get(.Subrole)
    let enabled = (try? element.get(.Enabled) as Bool) ?? false
    let shortcut = Self.shortcut(for: element)

    var actions: [String]?
    var attributes: [String: String]?
    var settable: [String]?
    var parameterized: [String]?
    var actionDescriptions: [String: String]?
    if diagnostics && captureDiagnostics {
      let names = element.attributeNames()
      let actionList = element.actionNames()
      actions = actionList
      attributes = Self.values(of: names, on: element)
      settable = names.filter { element.isAttributeSettable($0) }
      parameterized = element.parameterizedAttributeNames()
      actionDescriptions = Dictionary(uniqueKeysWithValues:
        actionList.compactMap { name in element.actionDescription(name).map { (name, $0) } })
    }

    return MenuNode(
      title: title, path: path, positionPath: positionPath, depth: depth,
      enabled: enabled, role: role, subrole: subrole, hasSubmenu: hasSubmenu,
      shortcut: shortcut, actions: actions, attributes: attributes,
      settableAttributes: settable, parameterizedAttributes: parameterized,
      actionDescriptions: actionDescriptions, children: nil)
  }

  private static func shortcut(for element: AX.Element) -> ShortcutInfo? {
    let extracted = MenuItemShortcut.extract(from: element, logger: logger)
    guard let key = extracted.character, !key.isEmpty else { return nil }
    let modifiers = extracted.modifiers ?? []
    let display = modifiers.joinWith(extracted.symbolName == nil ? key : key)
    return ShortcutInfo(
      key: key, modifiers: modifierNames(modifiers), display: display)
  }

  private static func modifierNames(_ m: Modifiers) -> [String] {
    var out: [String] = []
    if m.contains(.control)  { out.append("control") }
    if m.contains(.option)   { out.append("option") }
    if m.contains(.shift)    { out.append("shift") }
    if m.contains(.command)  { out.append("command") }
    if m.contains(.function) { out.append("function") }
    return out
  }

  private static func values(of names: [String], on element: AX.Element) -> [String: String] {
    var out: [String: String] = [:]
    for name in names {
      if let value = element.attributeValueDescription(name) {
        out[name] = value
      }
    }
    return out
  }
}
