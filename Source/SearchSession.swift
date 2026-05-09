//
//  SearchSession.swift
//  Menuet
//

import AppKit
import Foundation


/// State for the menu-search panel: typed query, fuzzy results, current
/// selection, and the keystroke pulses that drive UI feedback. Reads its
/// source data from a shared `MenuIndexProvider`.
class SearchSession: ObservableObject {

  static let shared = SearchSession()

  @Published var activeItem: MenuItem?
  @Published var searchResults: [MenuItem]
  @Published var query: String
  @Published var focusTrigger: Bool = false
  @Published var blockedReturnPulse: Int = 0

  private let menus: MenuIndexProvider
  private var selectedResult: Int

  public var totalResults: Int { searchResults.count }

  init(menus: MenuIndexProvider = .shared) {
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

  func search(_ query: String) {
    selectedResult = -1
    activeItem = nil
    if query.count > 0 {
      searchResults = menus.index.find(query: query)
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
