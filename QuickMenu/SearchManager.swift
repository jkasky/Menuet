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
  private var searchResults: [MenuItem]
  private var workspace: NSWorkspace
  
  private var currentApp: NSRunningApplication?
  private var currentIndex: MenuIndex
  
  private init() {
    axClient = AX.Client()
    workspace = NSWorkspace.shared
    searchResults = []
    currentApp = nil
    currentIndex = MenuIndex()
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
      walker.walk(visitor: AXMenuIndexer(index: currentIndex))
    }
    searchResults = currentIndex.find(query: query)
  }
}
