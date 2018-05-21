//
//  AXClient.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 4/17/17.
//  Copyright © 2017 Codjax. All rights reserved.
//

import Cocoa
import Foundation


extension AX {
  typealias Client = AXClient
}


class AXClient {

  func isProcessTrusted(withPrompt:Bool=false) -> Bool {
    if (withPrompt) {
      let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
      let options = [key: true]
      return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    return AXIsProcessTrusted()
  }

  func makeProcessTrusted(withPrompt:Bool=true) -> Bool {
    let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [key: withPrompt]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  func createApplication(application: NSRunningApplication) -> AX.Application {
    return AX.Application(pid: application.processIdentifier)
  }

  func createSystemWide() {
    AXUIElementCreateSystemWide()
  }
}
