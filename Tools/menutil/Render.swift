//
//  Render.swift
//  menutil
//
//  Tree/flat flattening, fuzzy filtering (the exact scorer Menuet search
//  uses), and text/JSON rendering.
//

import Foundation


enum Render {

  // MARK: - Shaping

  /// Depth-first flatten with `children` stripped — the shape used for JSON
  /// and for filtered output.
  static func flatten(_ nodes: [MenuNode]) -> [MenuNode] {
    var out: [MenuNode] = []
    func walk(_ ns: [MenuNode]) {
      for node in ns {
        var copy = node
        let kids = copy.children
        copy.children = nil
        out.append(copy)
        if let kids { walk(kids) }
      }
    }
    walk(nodes)
    return out
  }

  /// Fuzzy-filter + rank, mirroring `MenuIndex.find`: title score from
  /// `FuzzyMatch`, plus a small bonus for shallower paths, sorted desc.
  static func filtered(_ items: [MenuNode], query: String, caseSensitive: Bool = false) -> [MenuNode] {
    var scored: [(MenuNode, Int)] = []
    scored.reserveCapacity(items.count)
    for item in items {
      guard !item.title.isEmpty else { continue }
      guard let match = FuzzyMatch.score(
        query: query, candidate: item.title, caseSensitive: caseSensitive) else { continue }
      let pathBonus = max(0, 10 - item.path.count)
      scored.append((item, match.score + pathBonus))
    }
    return scored.sorted { $0.1 > $1.1 }.map { $0.0 }
  }

  // MARK: - JSON

  static func json(_ envelope: DumpEnvelope) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let data = try encoder.encode(envelope)
    return String(decoding: data, as: UTF8.self)
  }

  static func json<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let data = try encoder.encode(value)
    return String(decoding: data, as: UTF8.self)
  }

  // MARK: - Text

  /// Indented tree, one line per node (`children` walked recursively).
  static func tree(_ roots: [MenuNode], diagnostics: Bool) -> String {
    var lines: [String] = []
    func walk(_ nodes: [MenuNode], indent: Int) {
      let pad = String(repeating: "  ", count: indent)
      for node in nodes {
        lines.append(pad + titleLabel(node))
        if diagnostics { appendDiagnostics(node, pad: pad + "    ", into: &lines) }
        if let kids = node.children { walk(kids, indent: indent + 1) }
      }
    }
    walk(roots, indent: 0)
    return lines.joined(separator: "\n")
  }

  /// Flat list, one line per item, each showing its full path. Used for
  /// `--filter` output.
  static func flatList(_ items: [MenuNode], diagnostics: Bool) -> String {
    var lines: [String] = []
    for item in items {
      lines.append(pathLabel(item))
      if diagnostics { appendDiagnostics(item, pad: "    ", into: &lines) }
    }
    return lines.joined(separator: "\n")
  }

  // MARK: - Labels

  private static func titleLabel(_ node: MenuNode) -> String {
    decorate(base: node.title.isEmpty ? "—" : node.title, node)
  }

  private static func pathLabel(_ node: MenuNode) -> String {
    decorate(base: node.path.joined(separator: " > "), node)
  }

  private static func decorate(base: String, _ node: MenuNode) -> String {
    var parts = [base]
    if let shortcut = node.shortcut { parts.append("[\(shortcut.display)]") }
    if !node.enabled { parts.append("(disabled)") }
    return parts.joined(separator: "  ")
  }

  private static func appendDiagnostics(_ node: MenuNode, pad: String, into lines: inout [String]) {
    if let actions = node.actions {
      lines.append(pad + "actions: " + (actions.isEmpty ? "(none)" : actions.joined(separator: ", ")))
    }
    if let attributes = node.attributes, !attributes.isEmpty {
      lines.append(pad + "attributes:")
      for key in attributes.keys.sorted() {
        lines.append(pad + "  \(key) = \(attributes[key] ?? "")")
      }
    }
    if let settable = node.settableAttributes {
      lines.append(pad + "settable: " + (settable.isEmpty ? "(none)" : settable.sorted().joined(separator: ", ")))
    }
    if let parameterized = node.parameterizedAttributes, !parameterized.isEmpty {
      lines.append(pad + "parameterized: " + parameterized.sorted().joined(separator: ", "))
    }
  }
}
