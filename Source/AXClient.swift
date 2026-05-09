//
//  AXClient.swift
//  Menuet
//
//

import ApplicationServices
import Cocoa
import Foundation


extension AX {
  typealias Client = AccessibilityClient
}


// Apple declares `kAXTrustedCheckOptionPrompt` as a global `var` in
// ApplicationServices' C headers, which strict concurrency flags as
// shared mutable state. The value is documented stable and used
// verbatim in every call. Hardcode the string to avoid the diagnostic
// without losing intent.
//
// Reference: HIServices/AXUIElement.h
private let trustedCheckOptionPromptKey: String = "AXTrustedCheckOptionPrompt"


protocol AccessibilityClient {

  /**
   Check if process is trusted accessibility client.

   - returns: true if process is trusted, false otherwise
   */
  func isProcessTrusted() -> Bool

  /**
   Make process trusted accessibility client.

   Prompt user asyncronously if process is untrusted. The prompt will not
   affect the return value.

   - parameter withPrompt: show prompt if process is not trusted
   - returns: true if process is trusted, false otherwise
   */
  func makeProcessTrusted(withPrompt: Bool) -> Bool

  /**
   Creates a new accessibility application from running app.

   - returns: new instance.
   */
  func createApplication(application: NSRunningApplication) -> AX.Application
}


class AXClient: AccessibilityClient {

  /// Per-call AX messaging timeout in seconds. Applied to the system-wide
  /// accessibility object, which per Apple's docs scopes the timeout
  /// globally for this process — every subsequent AX query (including
  /// the menu walk) gets bounded.
  ///
  /// Setting it on a non-system-wide element scopes only to that element
  /// and does NOT cascade to descendants, so the system-wide call is the
  /// only single-shot way to bound the walk.
  ///
  /// Override at runtime via `defaults write app.menuet axMessagingTimeout -float 1.0`.
  /// Values <= 0 fall back to the hardcoded default (0 has special
  /// meaning to AX: "use the global default", which we don't want).
  static let defaultMessagingTimeout: Float = 0.5

  static var configuredMessagingTimeout: Float {
    let stored = UserDefaults.standard.float(forKey: "axMessagingTimeout")
    return stored > 0 ? stored : defaultMessagingTimeout
  }

  init(messagingTimeout: Float = AXClient.configuredMessagingTimeout) {
    let systemWide = AXUIElementCreateSystemWide()
    _ = AXUIElementSetMessagingTimeout(systemWide, messagingTimeout)
  }

  func isProcessTrusted() -> Bool {
    return AXIsProcessTrusted()
  }

  func makeProcessTrusted(withPrompt: Bool=true) -> Bool {
    let options = [trustedCheckOptionPromptKey: withPrompt]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  func createApplication(application: NSRunningApplication) -> AX.Application {
    return AXApplication(pid: application.processIdentifier)
  }
}
