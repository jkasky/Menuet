//
//  AppTarget.swift
//  menutil
//
//  Resolves the target NSRunningApplication and lists candidate apps.
//

import AppKit
import Foundation


enum AppTargetError: Error, CustomStringConvertible {
  case noFrontmost
  case noProcess(pid_t)
  case notFound(String)

  var description: String {
    switch self {
    case .noFrontmost:
      return "No frontmost application found."
    case .noProcess(let pid):
      return "No running application with pid \(pid)."
    case .notFound(let needle):
      return "No running application matching '\(needle)' (by bundle id or name). Try `menutil apps`."
    }
  }
}


enum AppTarget {

  /// Resolve a target from the mutually-exclusive selectors. Defaults to the
  /// frontmost app when none is given. Note: run interactively, "frontmost"
  /// is usually your terminal — pass `--app`/`--pid` to target another app.
  static func resolve(pid: Int32?, app: String?) throws -> NSRunningApplication {
    if let pid {
      guard let running = NSRunningApplication(processIdentifier: pid) else {
        throw AppTargetError.noProcess(pid)
      }
      return running
    }
    if let app {
      let needle = app.lowercased()
      let match = NSWorkspace.shared.runningApplications.first { running in
        running.bundleIdentifier?.lowercased() == needle
          || running.localizedName?.lowercased() == needle
      }
      guard let match else { throw AppTargetError.notFound(app) }
      return match
    }
    guard let front = NSWorkspace.shared.frontmostApplication else {
      throw AppTargetError.noFrontmost
    }
    return front
  }

  static func info(for app: NSRunningApplication) -> AppInfo {
    AppInfo(
      pid: app.processIdentifier,
      bundleId: app.bundleIdentifier,
      name: app.localizedName,
      frontmost: app.isActive)
  }

  /// Apps with a regular activation policy (i.e. those with a menu bar),
  /// sorted by name.
  static func listable() -> [AppInfo] {
    NSWorkspace.shared.runningApplications
      .filter { $0.activationPolicy == .regular }
      .map(info(for:))
      .sorted { ($0.name ?? "") .localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
  }
}
