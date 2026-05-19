//
//  SearchSession.swift
//  Menuet
//

import AppKit
import Foundation


/// State for the menu-search panel: typed query, fuzzy results, current
/// selection, and the keystroke pulses that drive UI feedback. Reads its
/// source data from a shared `MenuIndexProvider`.
@Observable
@MainActor
final class SearchSession {

  var activeItem: MenuItem?
  var searchResults: [MenuItem]
  var query: String
  var focusTrigger: Bool = false
  var blockedReturnPulse: Int = 0

  private let menus: IndexProvider
  private(set) var selectedResult: Int

  public var totalResults: Int { searchResults.count }

  init(menus: IndexProvider) {
    self.menus = menus
    searchResults = []
    query = ""
    selectedResult = -1
    activeItem = nil
  }

  func hasResults() -> Bool {
    return searchResults.count > 0
  }

  func findMatchingResult(_ matcher: (_ item: MenuItem) -> Bool) -> MenuItem? {
    return searchResults.first(where: matcher)
  }

  func selectNext() {
    guard !searchResults.isEmpty else { return }
    selectedResult = (max(selectedResult, 0) + 1) % searchResults.count
    activateSelected()
  }

  func selectPrevious() {
    guard !searchResults.isEmpty else { return }
    let count = searchResults.count
    let current = selectedResult < 0 ? 0 : selectedResult
    selectedResult = (current - 1 + count) % count
    activateSelected()
  }

  func activateSelected() {
    guard selectedResult >= 0 && selectedResult < searchResults.count else {
      activeItem = nil
      return
    }
    activeItem = searchResults[selectedResult]
  }

  func search(_ query: String) {
    if query.count > 0 {
      searchResults = menus.index.find(query: query)
      selectedResult = searchResults.isEmpty ? -1 : 0
      activateSelected()
    } else {
      clear()
    }
  }

  /// Clears the typed query, results, and the highlighted item. The
  /// underlying menu index (held by `MenuIndexProvider`) is untouched.
  func clear() {
    query = ""
    searchResults.removeAll()
    selectedResult = -1
    activeItem = nil
  }
}
