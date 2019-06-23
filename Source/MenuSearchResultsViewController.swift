//
//  MenuSearchResultsViewController.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 2019-01-01.
//  Copyright © 2019 Codjax. All rights reserved.
//

import Cocoa
import Foundation


class MenuSearchResultsViewController: NSViewController, NSTableViewDelegate {
  
  @IBOutlet
  weak var tableView: NSTableView!
  
  var searchManager: SearchManager!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsColumnReordering = false
    tableView.allowsColumnResizing = false
    tableView.allowsColumnSelection = false
    tableView.allowsEmptySelection = false
    tableView.allowsMultipleSelection = false
    
    searchManager = SearchManager.shared
  }
  
  func tableView(_ tableView: NSTableView,
                 viewFor tableColumn: NSTableColumn?,
                 row: Int) -> NSView? {
    guard row < searchManager.searchResults.count else {
      return nil
    }

    let item = searchManager.searchResults[row]

    let resultView = tableView.makeView(
      withIdentifier: tableColumn!.identifier,
      owner: self
    ) as! SearchResultTableCellView

    resultView.itemField.stringValue = item.title
    resultView.hotKeyField.stringValue = item.command.stringValue
    let parentIndex = item.path.endIndex - 2;
    var parentPath = item.path[0...parentIndex]
    if parentPath[0] == "Apple" {
      parentPath[0] = KeyGlyph.Apple.characters
    }
    resultView.pathField.stringValue = parentPath.joined(separator: " > ")

    if row < 7 {
      resultView.quickField.stringValue = "\(KeyGlyph.Command.characters)" +
                                          "\(row + 1)"
    } else {
      resultView.quickField.stringValue = ""
    }

    return resultView;
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    guard tableView.selectedRow >= 0 else {
      return
    }
    searchManager.selectResult(at: tableView.selectedRow)
  }
}


class SearchResultTableCellView: NSTableCellView {

  @IBOutlet weak var itemField: NSTextField!
  @IBOutlet weak var pathField: NSTextField!
  @IBOutlet weak var hotKeyField: NSTextField!
  @IBOutlet weak var quickField: NSTextField!
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
