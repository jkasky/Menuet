//
//  Permissions.swift
//  menutil
//

import ApplicationServices
import ArgumentParser
import Foundation


// Apple declares `kAXTrustedCheckOptionPrompt` as a global `var`, which strict
// concurrency flags as shared mutable state. Hardcode the documented string,
// matching `AXClient`.
private let trustedCheckOptionPromptKey = "AXTrustedCheckOptionPrompt"


enum Permissions {

  /// Exits with guidance unless this binary is a trusted Accessibility client.
  /// On the first untrusted run we also fire the system prompt, which opens the
  /// Privacy ▸ Accessibility pane (it doesn't change the current result, so we
  /// still exit and ask the user to re-run after granting).
  static func ensureAccessibilityTrust() throws {
    guard !AXIsProcessTrusted() else { return }
    _ = AXIsProcessTrustedWithOptions([trustedCheckOptionPromptKey: true] as CFDictionary)
    FileHandle.standardError.write(Data("""
      menutil needs Accessibility permission to read other apps' menus.

      Grant it in System Settings ▸ Privacy & Security ▸ Accessibility
      (the pane was just opened), enable "menutil", then re-run.

      The grant persists across rebuilds because the binary is code-signed.

      """.utf8))
    throw ExitCode.failure
  }
}
