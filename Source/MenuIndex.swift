//
//  MenuIndex.swift
//  Menuet
//

import Foundation


class MenuIndex {

  private var items: [MenuItem] = []

  /// Set to `false` by `MenuIndexProvider.refresh()` when the underlying
  /// walker bailed at its deadline before visiting every menu. Views use
  /// this together with `isEmpty` to show "{app} isn't responding."
  var isComplete: Bool = true

  var size: Int {
    return items.count
  }

  var isEmpty: Bool {
    return items.isEmpty
  }

  func add(_ item: MenuItem) {
    items.append(item)
  }

  func itemsWithShortcuts() -> [MenuItem] {
    return items.filter { !$0.command.character.isEmpty }
  }

  func find(query: String) -> [MenuItem] {
    guard !query.isEmpty else { return [] }
    let caseSensitive = UserDefaults.standard.searchMatchCase
    let showDisabled = UserDefaults.standard.showDisabledItems

    var scored: [(MenuItem, Int)] = []
    scored.reserveCapacity(items.count)
    for item in items {
      guard !item.title.isEmpty else { continue }
      guard showDisabled || item.enabled else { continue }
      guard let match = FuzzyMatch.score(
        query: query, candidate: item.title, caseSensitive: caseSensitive)
      else { continue }
      let pathBonus = max(0, 10 - item.path.count)
      scored.append((item, match.score + pathBonus))
    }
    return scored.sorted { $0.1 > $1.1 }.map { $0.0 }
  }
}
