//
//  AXClient.swift
//  Menuet
//
//

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
