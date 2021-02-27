//
//  AXClient.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 4/17/17.
//  Copyright © 2017 Codjax. All rights reserved.
//

import Cocoa
import Foundation


extension AX {
  typealias Client = AccessibilityClient
}


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
    let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [key: withPrompt]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  func createApplication(application: NSRunningApplication) -> AX.Application {
    return AXApplication(pid: application.processIdentifier)
  }
}
