//
//  MenuIndexProvider.swift
//  Menuet
//

import AppKit
import Foundation
import Sentry


/// Walks the AX menu tree of the frontmost app and exposes the resulting
/// `MenuIndex`. This is the single source of truth for "what menu does the
/// target app have right now"; sessions read from it.
@Observable
@MainActor
final class IndexProvider {

  /// Wall-clock budget for a single menu walk. Once exceeded, the walker
  /// bails and `MenuIndex.isComplete` is flipped to false so views can
  /// surface "{app} isn't responding."
  ///
  /// Override at runtime via `defaults write app.menuet axWalkDeadline -float 1.5`.
  /// Values <= 0 fall back to the hardcoded default.
  static let defaultWalkDeadline: TimeInterval = 2.0

  static var configuredWalkDeadline: TimeInterval {
    let stored = UserDefaults.standard.double(forKey: Preference.axWalkDeadline)
    return stored > 0 ? stored : defaultWalkDeadline
  }

  private(set) var currentApp: NSRunningApplication?
  private(set) var index: MenuIndex = MenuIndex()
  /// Reflects `AXIsProcessTrusted()` as of the most recent `refresh()`.
  /// Defaults to `true` so the panels don't flash a "needs permission"
  /// state on the very first hotkey before we've checked. Updated on
  /// every refresh, so revoking permission while Menuet is running is
  /// detected on the next invocation.
  private(set) var isTrusted: Bool = true

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
    let transaction = SentrySDK.startTransaction(
      name: "menu.refresh", operation: "ax.walk", bindToScope: true)
    defer {
      transaction.finish()
      SentrySDK.configureScope { $0.span = nil }
    }

    // Re-check on every refresh so a permission revoke (or a grant after
    // first launch without quitting) is reflected in the next panel
    // open rather than silently producing empty results.
    guard axClient.isProcessTrusted() else {
      transaction.setData(value: "untrusted", key: "result")
      isTrusted = false
      currentApp = nil
      index = MenuIndex()
      return
    }
    isTrusted = true

    guard let app = workspace.menuBarOwningApplication else {
      transaction.setData(value: "no_menubar_owner", key: "result")
      currentApp = nil
      index = MenuIndex()
      return
    }
    transaction.setData(value: app.bundleIdentifier ?? "unknown", key: "target.bundle_id")

    let next = MenuIndex()
    let walker = AXMenuWalker(application: axClient.createApplication(application: app))
    let deadline = Date().addingTimeInterval(Self.configuredWalkDeadline)
    let visitor = TracingMenuVisitor(
      AXMenuIndexer(index: next), bundleId: app.bundleIdentifier ?? "unknown")
    let didComplete = walker.walk(visitor: visitor, deadline: deadline)
    next.isComplete = didComplete
    currentApp = app
    index = next

    transaction.setData(value: didComplete, key: "walk.complete")
    transaction.setData(value: next.size, key: "menu.size")
  }

  func clear() {
    currentApp = nil
    if index.size > 0 {
      index = MenuIndex()
    }
  }
}


/// Wraps another visitor and starts a Sentry child span for each top-level
/// menu (depth-0 enterMenu/leaveMenu pair). No spans for nested submenus or
/// individual items — keeps span count bounded to ~10 per walk.
private final class TracingMenuVisitor: AXMenuVisitor {

  private let inner: AXMenuVisitor
  private let bundleId: String
  private var depth = 0
  private var spanStack: [Span] = []

  init(_ inner: AXMenuVisitor, bundleId: String) {
    self.inner = inner
    self.bundleId = bundleId
  }

  func enterMenu(_ element: AX.Element) {
    if depth == 0, let parent = SentrySDK.span {
      let title: String = (try? element.get(.Title)) ?? "?"
      let span = parent.startChild(operation: "ax.walk.menu", description: title)
      span.setData(value: bundleId, key: "target.bundle_id")
      spanStack.append(span)
    }
    depth += 1
    inner.enterMenu(element)
  }

  func leaveMenu(_ element: AX.Element) {
    depth -= 1
    inner.leaveMenu(element)
    if depth == 0, let span = spanStack.popLast() {
      span.finish()
    }
  }

  func visitMenuItem(_ element: AX.Element) {
    inner.visitMenuItem(element)
  }
}
