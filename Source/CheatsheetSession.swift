//
//  CheatsheetSession.swift
//  Menuet
//

import AppKit
import Foundation


/// State for the keyboard-shortcut cheatsheet panel: which groups are
/// displayed, the typed filter query, the modifier-key filter, and which
/// item is currently highlighted. Reads its source data from a shared
/// `MenuIndexProvider`.
@MainActor
final class CheatsheetSession: ObservableObject {

  static let shared = CheatsheetSession()

  @Published var groups: [CheatsheetGroup] = []
  @Published var resetTrigger: Bool = false
  @Published var query: String = ""
  @Published var activeItem: MenuItem?
  @Published private(set) var matchIDs: Set<UUID> = []
  @Published private(set) var modifierFilter: NSEvent.ModifierFlags = []

  private var matchOrder: [MenuItem] = []
  private let menus: MenuIndexProvider

  init(menus: MenuIndexProvider = .shared) {
    self.menus = menus
  }

  var filteredGroups: [CheatsheetGroup] {
    if modifierFilter.isEmpty { return groups }
    return groups.compactMap { group in
      let items = group.items.filter {
        $0.command.modifiers.containsFilter(modifierFilter)
      }
      return items.isEmpty ? nil : CheatsheetGroup(menu: group.menu, items: items)
    }
  }

  func load() {
    groups = Self.groupForCheatsheet(menus.index.itemsWithShortcuts())
    clearQuery()
  }

  func append(_ character: Character) {
    query.append(character)
    recomputeMatches()
  }

  func backspace() {
    guard !query.isEmpty else { return }
    query.removeLast()
    recomputeMatches()
  }

  func clearQuery() {
    query = ""
    matchOrder = []
    matchIDs = []
    activeItem = nil
    modifierFilter = []
  }

  func updateModifierFilter(_ flags: NSEvent.ModifierFlags) {
    guard flags != modifierFilter else { return }
    modifierFilter = flags
  }

  func selectNextMatch() {
    guard !matchOrder.isEmpty else { return }
    let nextIndex: Int
    if let active = activeItem,
       let i = matchOrder.firstIndex(where: { $0.id == active.id }) {
      nextIndex = (i + 1) % matchOrder.count
    } else {
      nextIndex = 0
    }
    activeItem = matchOrder[nextIndex]
  }

  private func recomputeMatches() {
    if query.isEmpty {
      matchOrder = []
      matchIDs = []
      activeItem = nil
      return
    }
    let caseSensitive = UserDefaults.standard.searchCaseSensitive
    // Walk groups in display order so Tab visits matches top-to-bottom
    // through the rendered list. Keep the score so we can still seed the
    // initial highlight with the best fuzzy match.
    var inDisplayOrder: [(MenuItem, Int)] = []
    for group in groups {
      for item in group.items {
        guard !item.title.isEmpty else { continue }
        guard let match = FuzzyMatch.score(
          query: query,
          candidate: item.title,
          caseSensitive: caseSensitive)
        else { continue }
        inDisplayOrder.append((item, match.score))
      }
    }
    matchOrder = inDisplayOrder.map { $0.0 }
    matchIDs = Set(matchOrder.map(\.id))
    activeItem = inDisplayOrder.max { $0.1 < $1.1 }?.0
  }

  func item(matching event: NSEvent) -> MenuItem? {
    var characters = event.charactersIgnoringModifiers?.uppercased()
    if characters == nil || characters == "" {
      characters = event.characters?.uppercased()
    }
    guard let target = characters, !target.isEmpty else { return nil }
    for group in groups {
      for item in group.items {
        if item.command.character.uppercased() == target
          && item.command.modifiers == event.modifierFlags {
          return item
        }
      }
    }
    return nil
  }

  static func groupForCheatsheet(_ items: [MenuItem]) -> [CheatsheetGroup] {
    var order: [String] = []
    var buckets: [String: [MenuItem]] = [:]
    for item in items {
      guard let menu = item.path.first, !menu.isEmpty else { continue }
      if menu == MenuItem.appleMenuTitle { continue }
      if buckets[menu] == nil {
        order.append(menu)
        buckets[menu] = []
      }
      buckets[menu]?.append(item)
    }
    return order.map { CheatsheetGroup(menu: $0, items: buckets[$0] ?? []) }
  }
}


struct CheatsheetGroup: Identifiable {
  var id: String { menu }
  let menu: String
  let items: [MenuItem]
}
