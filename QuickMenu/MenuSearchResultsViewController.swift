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
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    guard tableView.selectedRow >= 0 else {
      return
    }
    SearchManager.shared.selectResult(at: tableView.selectedRow)
  }
}
