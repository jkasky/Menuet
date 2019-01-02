//
//  MenuSearchResultsDataSource.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 2019-01-01.
//  Copyright © 2019 Codjax. All rights reserved.
//

import Cocoa
import Foundation


class MenuSearchResultsDataSource: NSObject, NSTableViewDataSource {
  
  var searchManager: SearchManager
  
  override init() {
    searchManager = SearchManager.shared
    super.init()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return searchManager.searchResults.count
  }
  
  func tableView(_ tableView: NSTableView,
                 objectValueFor tableColumn: NSTableColumn?,
                 row: Int) -> Any? {
    return searchManager.searchResults[row].title
  }
}
