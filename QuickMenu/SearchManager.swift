//
//  SearchManager.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 2018-12-29.
//  Copyright © 2018 Codjax. All rights reserved.
//

import AppKit
import Foundation


class SearchManager {
  
  static let shared = SearchManager()
  
  private var axClient: AX.Client
  private var workspace: NSWorkspace
  
  private var currentIndex: MenuIndex
  private var selectedResult: Int
  
  public var currentApp: NSRunningApplication?
  public var searchResults: [MenuItem]

  private init() {
    axClient = AX.Client()
    workspace = NSWorkspace.shared
    searchResults = []
    selectedResult = -1
    currentApp = nil
    currentIndex = MenuIndex()
  }
  
  func selectResult(at index: Int) {
    selectedResult = index
  }
  
  func performSelected() {
    guard selectedResult >= 0 else {
      return
    }
    searchResults[selectedResult].command.perform()
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
      searchResults = []
    }
  }
  
  func clear() {
    searchResults.removeAll()
    selectedResult = -1
  }
}
