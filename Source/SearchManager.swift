//
//  SearchManager.swift
//  Menuet
//
//

import AppKit
import Combine
import Foundation


class SearchManager: ObservableObject {

  @Published var activeItem: MenuItem?
  @Published var currentApp: NSRunningApplication?
  @Published var searchResults: [MenuItem]
  @Published var query: String
  @Published var focusTrigger: Bool = false
  @Published var cheatsheetGroups: [CheatsheetGroup] = []
  @Published var cheatsheetResetTrigger: Bool = false
  @Published var cheatsheetQuery: String = ""
  @Published var cheatsheetActiveItem: MenuItem?
  @Published private(set) var cheatsheetMatchIDs: Set<UUID> = []
  @Published private(set) var cheatsheetModifierFilter: NSEvent.ModifierFlags = []
  @Published var blockedReturnPulse: Int = 0
  private var cheatsheetMatchOrder: [MenuItem] = []

  var filteredCheatsheetGroups: [CheatsheetGroup] {
    if cheatsheetModifierFilter.isEmpty { return cheatsheetGroups }
    return cheatsheetGroups.compactMap { group in
      let items = group.items.filter {
        $0.command.modifiers.containsFilter(cheatsheetModifierFilter)
      }
      return items.isEmpty ? nil : CheatsheetGroup(menu: group.menu, items: items)
    }
  }

  static let shared = SearchManager()

  private let menus: MenuIndexProvider

  private var currentIndex: MenuIndex { menus.index }
  private var selectedResult: Int

  public var totalResults: Int {
    get {
      return searchResults.count
    }
  }

  init(menus: MenuIndexProvider = MenuIndexProvider()) {
    self.menus = menus
    searchResults = []
    query = ""
    selectedResult = -1
    activeItem = nil
    menus.$currentApp.assign(to: &$currentApp)
  }
  
  func hasResults() -> Bool {
    return searchResults.count > 0
  }
  
  func findMatchingResult(_ matcher: (_ item: MenuItem) -> Bool) -> MenuItem? {
    return searchResults.first(where: matcher)
  }

  func selectNext() {
    if selectedResult < searchResults.count - 1 {
      selectedResult += 1
      activateSelected()
    }
  }

  func selectPrevious() {
    if selectedResult > 0 {
      selectedResult -= 1
    } else {
      selectedResult = -1
    }
    activateSelected()
  }
  
  func activateSelected() {
    guard selectedResult >= 0 && selectedResult < searchResults.count else {
      activeItem = nil
      return
    }
    activeItem = searchResults[selectedResult]
  }

  func activate() {
    menus.refresh()
    cheatsheetGroups = []
  }

  func loadCheatsheetGroups() {
    cheatsheetGroups = Self.groupForCheatsheet(currentIndex.itemsWithShortcuts())
    cheatsheetClearQuery()
  }

  func cheatsheetAppend(_ character: Character) {
    cheatsheetQuery.append(character)
    recomputeCheatsheetMatches()
  }

  func cheatsheetBackspace() {
    guard !cheatsheetQuery.isEmpty else { return }
    cheatsheetQuery.removeLast()
    recomputeCheatsheetMatches()
  }

  func cheatsheetClearQuery() {
    cheatsheetQuery = ""
    cheatsheetMatchOrder = []
    cheatsheetMatchIDs = []
    cheatsheetActiveItem = nil
    cheatsheetModifierFilter = []
  }

  func cheatsheetUpdateModifierFilter(_ flags: NSEvent.ModifierFlags) {
    guard flags != cheatsheetModifierFilter else { return }
    cheatsheetModifierFilter = flags
  }

  func cheatsheetSelectNextMatch() {
    guard !cheatsheetMatchOrder.isEmpty else { return }
    let nextIndex: Int
    if let active = cheatsheetActiveItem,
       let i = cheatsheetMatchOrder.firstIndex(where: { $0.id == active.id }) {
      nextIndex = (i + 1) % cheatsheetMatchOrder.count
    } else {
      nextIndex = 0
    }
    cheatsheetActiveItem = cheatsheetMatchOrder[nextIndex]
  }

  private func recomputeCheatsheetMatches() {
    if cheatsheetQuery.isEmpty {
      cheatsheetMatchOrder = []
      cheatsheetMatchIDs = []
      cheatsheetActiveItem = nil
      return
    }
    let caseSensitive = UserDefaults.standard.searchCaseSensitive
    // Walk groups in display order so Tab visits matches top-to-bottom
    // through the rendered list. Keep the score so we can still seed the
    // initial highlight with the best fuzzy match.
    var inDisplayOrder: [(MenuItem, Int)] = []
    for group in cheatsheetGroups {
      for item in group.items {
        guard !item.title.isEmpty else { continue }
        guard let match = FuzzyMatch.score(
          query: cheatsheetQuery,
          candidate: item.title,
          caseSensitive: caseSensitive)
        else { continue }
        inDisplayOrder.append((item, match.score))
      }
    }
    cheatsheetMatchOrder = inDisplayOrder.map { $0.0 }
    cheatsheetMatchIDs = Set(cheatsheetMatchOrder.map(\.id))
    cheatsheetActiveItem = inDisplayOrder.max { $0.1 < $1.1 }?.0
  }

  func cheatsheetItem(matching event: NSEvent) -> MenuItem? {
    var characters = event.charactersIgnoringModifiers?.uppercased()
    if characters == nil || characters == "" {
      characters = event.characters?.uppercased()
    }
    guard let target = characters, !target.isEmpty else { return nil }
    for group in cheatsheetGroups {
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

  func search(_ query: String) {
    selectedResult = -1
    activeItem = nil
    if query.count > 0 {
      searchResults = currentIndex.find(query: query)
    } else {
      clear()
    }
  }
  
  /**
   * Clears the search query, results, selected result, and any active item.
   */
  func clear() {
    query = ""
    searchResults.removeAll()
    selectedResult = -1
    activeItem = nil
  }

  /**
   * Resets the search manager to a completely fresh state - no results, index.
   *
   * Calling reset removes the current index and all menu entries in it. A
   * subsequent search will require a new index even if the app has not changed.
   * Performing an action on a menu item must occur before the index is removed.
   * Generally, the search manager should be reset before each new search so
   * that if the menu state changes or the frontmost app is switched then the
   * new index will have the most current state.
   */
  func reset() {
    clear()
    cheatsheetClearQuery()
    cheatsheetGroups = []
    menus.clear()
  }
}


struct CheatsheetGroup: Identifiable {
  var id: String { menu }
  let menu: String
  let items: [MenuItem]
}
