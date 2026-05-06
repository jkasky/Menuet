//
//  FakeAXClient.swift
//  MenuetTests
//

import AppKit
import Foundation


class FakeAXClient: AccessibilityClient {

  var trusted: Bool = true
  var createdApp: AX.Application = FakeAXApplication()

  func isProcessTrusted() -> Bool {
    return trusted
  }

  func makeProcessTrusted(withPrompt: Bool) -> Bool {
    return trusted
  }

  func createApplication(application: NSRunningApplication) -> AX.Application {
    return createdApp
  }
}
