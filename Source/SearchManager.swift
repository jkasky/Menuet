//
//  SearchManager.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 2018-12-29.
//  Copyright © 2018 Codjax. All rights reserved.
//

import AppKit
import Foundation


enum SearchEvent: String {
  case ResultsChanged = "searchResultsChanged"

  var name: Notification.Name {
    get {
      return Notification.Name(self.rawValue)
    }
  }

  func notification() -> Notification {
    return Notification(name: Notification.Name(self.rawValue))
  }

  func observe(_ observer: Any, _ selector: Selector) {
    NotificationCenter.default.addObserver(
      observer,
      selector: selector,
      name: self.name, object: nil)
  }
}


class SearchManager {
  
  static let shared = SearchManager()
  
  private var axClient: AX.Client
  private var workspace: NSWorkspace
  
  private var currentIndex: MenuIndex
  private var selectedResult: Int
  private var searchResults: [MenuItem]
  
  public var currentApp: NSRunningApplication?
  public var activeItem: MenuItem?
  
  public var totalResults: Int {
    get {
      return searchResults.count
    }
  }

  private init() {
    axClient = AX.Client()
    workspace = NSWorkspace.shared
    searchResults = []
    selectedResult = -1
    currentApp = nil
    currentIndex = MenuIndex()
    activeItem = nil
  }
  
  func hasResults() -> Bool {
    return searchResults.count > 0
  }
  
  func getResult(at index: Int) -> MenuItem {
    return searchResults[index]
  }
  
  func selectResult(at index: Int) {
    selectedResult = index
  }
  
  func activateSelected() {
    guard selectedResult >= 0 && searchResults.count > 0 else {
      return
    }
    activeItem = searchResults[selectedResult]
  }
  
  func search(_ query: String) {
    let menuBarApp = workspace.menuBarOwningApplication
    guard menuBarApp != nil else {
      return
    }
    if menuBarApp != currentApp {
      currentApp = menuBarApp
      let axApp = axClient.createApplication(application:menuBarApp!)
      let walker = AXMenuWalker(application: axApp.topElement)
      currentIndex = MenuIndex()
      try? walker.walk(visitor: AXMenuIndexer(index: currentIndex))
    }
    if query.count > 0 {
      searchResults = currentIndex.find(query: query)
    } else {
      clear()
    }
    NotificationCenter.default.post(SearchEvent.ResultsChanged.notification())
  }
  
  /**
   * Clears the search results, selected result, and any active item.
   */
  func clear() {
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
    currentApp = nil
    if currentIndex.size > 0 {
      currentIndex = MenuIndex()
    }
  }
}
