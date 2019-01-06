//
//  MenuSearchResultsViewController.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 2019-01-01.
//  Copyright © 2019 Codjax. All rights reserved.
//

import Cocoa
import Foundation


class MenuSearchResultsViewController: NSViewController, NSTableViewDelegate {
  
  @IBOutlet
  weak var tableView: NSTableView!
  
  var searchManager: SearchManager?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsColumnReordering = false
    tableView.allowsColumnResizing = false
    tableView.allowsColumnSelection = false
    tableView.allowsEmptySelection = false
    tableView.allowsMultipleSelection = false
    
    searchManager = SearchManager.shared
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    guard tableView.selectedRow >= 0 else {
      return
    }
    searchManager?.selectResult(at: tableView.selectedRow)
  }
}


extension NSTableView {
  
  func selectNextRow(_ sender: Any?) {
    if (selectedRow == -1) {
      selectRowIndexes(
        IndexSet(integer: 0),
        byExtendingSelection: false)
    } else {
      selectRowIndexes(
        IndexSet(integer: selectedRow + 1),
        byExtendingSelection: false)
    }
    scrollRowToVisible(selectedRow)
  }
  
  func selectPreviousRow(_ sender: Any?) {
    if selectedRow > 0 {
      selectRowIndexes(
        IndexSet(integer: selectedRow - 1),
        byExtendingSelection: false)
    }
    scrollRowToVisible(selectedRow)
  }
}
