//
//  MenuIndexProvider.swift
//  Menuet
//

import AppKit
import Foundation


/// Walks the AX menu tree of the frontmost app and exposes the resulting
/// `MenuIndex`. This is the single source of truth for "what menu does the
/// target app have right now"; sessions read from it.
final class MenuIndexProvider: ObservableObject {

  static let shared = MenuIndexProvider()

  @Published private(set) var currentApp: NSRunningApplication?
  @Published private(set) var index: MenuIndex = MenuIndex()

  private let axClient: AX.Client
  private let workspace: NSWorkspace

  init(axClient: AX.Client = AXClient(), workspace: NSWorkspace = .shared) {
    self.axClient = axClient
    self.workspace = workspace
  }

  /// Walks the menu bar of the current frontmost (non-Menuet) app and
  /// publishes a fresh index. Must be called before stealing key focus —
  /// see CLAUDE.md "walk before stealing focus."
  func refresh() {
    guard let app = workspace.menuBarOwningApplication else {
      currentApp = nil
      index = MenuIndex()
      return
    }
    let next = MenuIndex()
    let walker = AXMenuWalker(application: axClient.createApplication(application: app))
    walker.walk(visitor: AXMenuIndexer(index: next))
    currentApp = app
    index = next
  }

  func clear() {
    currentApp = nil
    if index.size > 0 {
      index = MenuIndex()
    }
  }
}
