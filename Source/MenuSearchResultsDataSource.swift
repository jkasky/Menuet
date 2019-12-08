//
//  MenuSearchResultsDataSource.swift
//  MenuFinder
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
    return searchManager.totalResults
  }
  
  func tableView(_ tableView: NSTableView,
                 objectValueFor tableColumn: NSTableColumn?,
                 row: Int) -> Any? {
    guard row < searchManager.totalResults else {
      return nil
    }
    let item = searchManager.getResult(at: row)
    switch tableColumn?.identifier.rawValue {
    case "menuItemTitle":
      return item.title
    case "menuItemCommand":
      return item.command.stringValue
    default:
      break
    }
    return ""
  }
}
