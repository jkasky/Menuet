//
//  ViewController.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 6/24/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Cocoa


class MenuSearchViewController: NSViewController, NSTextDelegate {

  @IBOutlet
  weak var queryTextField: NSTextField!
  
  @IBOutlet
  weak var searchMenuResultsTableView: NSTableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.queryTextField.isBezeled = false
    self.queryTextField.isBordered = false
  }

  override func controlTextDidChange(_ notification: Notification) {
    SearchManager.shared.search(queryTextField.stringValue)
    searchMenuResultsTableView.reloadData()
  }
}

