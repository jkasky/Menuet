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
  @Published var blockedReturnPulse: Int = 0

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
}
