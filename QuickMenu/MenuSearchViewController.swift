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
  weak var appIconImageView: NSImageView!
  
  @IBOutlet
  weak var queryTextField: NSTextField!
  
  @IBOutlet
  weak var searchMenuResultsTableView: NSTableView!
  
  var searchManager: SearchManager?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.queryTextField.isBezeled = false
    self.queryTextField.isBordered = false
    searchManager = SearchManager.shared
  }
  
  override func viewWillAppear() {
    let currentApp = NSWorkspace.shared.menuBarOwningApplication
    appIconImageView.image = currentApp?.icon
  }
  
  override func viewDidAppear() {
    queryTextField.becomeFirstResponder()
  }
  
  override func viewDidDisappear() {
    searchManager?.clear()
    queryTextField.stringValue = ""
    searchMenuResultsTableView.reloadData()
  }

  override func controlTextDidChange(_ notification: Notification) {
    searchManager?.search(queryTextField.stringValue)
    searchMenuResultsTableView.reloadData()
  }
}

