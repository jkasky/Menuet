//
//  MenuIndexProvider.swift
//  Menuet
//

import AppKit
import Foundation


/// Walks the AX menu tree of the frontmost app and exposes the resulting
/// `MenuIndex`. This is the single source of truth for "what menu does the
/// target app have right now"; sessions read from it.
@MainActor
final class MenuIndexProvider: ObservableObject {

  /// Wall-clock budget for a single menu walk. Once exceeded, the walker
  /// bails and `MenuIndex.isComplete` is flipped to false so views can
  /// surface "{app} isn't responding."
  ///
  /// Override at runtime via `defaults write app.menuet axWalkDeadline -float 1.5`.
  /// Values <= 0 fall back to the hardcoded default.
  static let defaultWalkDeadline: TimeInterval = 2.0

  static var configuredWalkDeadline: TimeInterval {
    let stored = UserDefaults.standard.double(forKey: "axWalkDeadline")
    return stored > 0 ? stored : defaultWalkDeadline
  }

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
    let deadline = Date().addingTimeInterval(Self.configuredWalkDeadline)
    let didComplete = walker.walk(visitor: AXMenuIndexer(index: next), deadline: deadline)
    next.isComplete = didComplete
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
