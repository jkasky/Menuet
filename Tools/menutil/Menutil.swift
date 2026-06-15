//
//  Menutil.swift
//  menutil
//
//  Entry point + subcommands for the menu-walking diagnostic CLI.
//

import AppKit
import ApplicationServices
import ArgumentParser
import Foundation


enum OutputFormat: String, ExpressibleByArgument {
  case text
  case json
}


@main
struct Menutil: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "menutil",
    abstract: "Walk and inspect an app's menu bar via the macOS Accessibility API.",
    discussion: """
      A command-line menu walker for diagnosing Menuet's AX behavior. Pick a
      target app, walk its menu tree, and print it as text or JSON — with
      optional deep diagnostics (per-item AX actions + every attribute) and
      Menuet's own fuzzy filter.
      """,
    version: "0.1.0",
    subcommands: [Apps.self, Walk.self],
    defaultSubcommand: Walk.self)
}


// MARK: - apps

struct Apps: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "List running apps that can be targeted (those with a menu bar).")

  @Flag(name: .long, help: "Output JSON instead of text.")
  var json = false

  func run() throws {
    let apps = AppTarget.listable()
    if json {
      print(try Render.json(apps))
    } else {
      for app in apps {
        let marker = app.frontmost ? "  *" : ""
        print("\(app.pid)\t\(app.bundleId ?? "-")\t\(app.name ?? "-")\(marker)")
      }
    }
  }
}


// MARK: - walk

struct Walk: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Walk a target app's menu tree and print it.")

  @Flag(help: "Target the frontmost app (default; usually your terminal when run interactively).")
  var front = false

  @Option(help: "Target by process id.")
  var pid: Int32?

  @Option(name: .long, help: "Target by bundle id or app name.")
  var app: String?

  @Option(help: "Fuzzy-filter by title; output becomes a flat, score-ranked list.")
  var filter: String?

  @Option(help: "Output format: text or json.")
  var format: OutputFormat = .text

  @Flag(name: .long, help: "Shortcut for --format json.")
  var json = false

  @Flag(name: .customLong("ax"),
        help: "Include each item's raw AX data: actions, all attributes, settability, parameterized attributes, and action descriptions.")
  var includeAX = false

  @Flag(help: "Include the Apple (system) menu.")
  var includeApple = false

  @Flag(help: "Drop disabled items.")
  var enabledOnly = false

  @Option(help: "Cap menu recursion depth (top-level menu = 1).")
  var depth: Int?

  @Option(help: "AX messaging timeout and walk deadline, in seconds.")
  var timeout: Double?

  func run() throws {
    try Permissions.ensureAccessibilityTrust()

    let running = try AppTarget.resolve(pid: pid, app: app)
    let appInfo = AppTarget.info(for: running)

    _ = AXUIElementSetMessagingTimeout(
      AXUIElementCreateSystemWide(), Float(timeout ?? 1.0))

    let axApp = AXApplication(pid: running.processIdentifier)
    let visitor = MenuDumpVisitor(
      diagnostics: includeAX,
      includeApple: includeApple,
      depthCap: depth ?? Int.max)
    let walker = AXMenuWalker(application: axApp)
    let deadline = Date().addingTimeInterval(timeout ?? 10.0)
    let complete = walker.walk(visitor: visitor, deadline: deadline)

    var roots = visitor.roots
    if enabledOnly { roots = Self.pruneDisabled(roots) }

    let useJSON = json || format == .json

    if let filter, !filter.isEmpty {
      let items = Render.filtered(Render.flatten(roots), query: filter)
      if useJSON {
        print(try Render.json(DumpEnvelope(app: appInfo, complete: complete, items: items)))
      } else if items.isEmpty {
        FileHandle.standardError.write(Data("No items match '\(filter)'.\n".utf8))
      } else {
        print(Render.flatList(items, diagnostics: includeAX))
      }
    } else if useJSON {
      let items = Render.flatten(roots)
      print(try Render.json(DumpEnvelope(app: appInfo, complete: complete, items: items)))
    } else {
      print(Render.tree(roots, diagnostics: includeAX))
    }

    if !complete {
      FileHandle.standardError.write(Data(
        "warning: walk hit its deadline before finishing (partial results). Raise --timeout.\n".utf8))
    }
  }

  /// Keep enabled leaves, and menus that still have an enabled descendant.
  private static func pruneDisabled(_ nodes: [MenuNode]) -> [MenuNode] {
    nodes.compactMap { node in
      guard let kids = node.children else {
        return node.enabled ? node : nil
      }
      let prunedKids = pruneDisabled(kids)
      guard node.enabled || !prunedKids.isEmpty else { return nil }
      var copy = node
      copy.children = prunedKids
      return copy
    }
  }
}
