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
  weak var queryField: NSTextField!
  
  @IBOutlet
  weak var searchMenuResultsTableView: NSTableView!
  
  var searchManager: SearchManager?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.queryField.isBezeled = false
    self.queryField.isBordered = false
    searchManager = SearchManager.shared
  }
  
  override func viewWillAppear() {
    let currentApp = NSWorkspace.shared.menuBarOwningApplication
    appIconImageView.image = currentApp?.icon
  }
  
  override func viewDidAppear() {
    queryField.becomeFirstResponder()
  }
  
  override func viewDidDisappear() {
    searchManager?.clear()
    queryField.stringValue = ""
    searchMenuResultsTableView.reloadData()
  }

  override func controlTextDidChange(_ notification: Notification) {
    searchManager?.search(queryField.stringValue)
    searchMenuResultsTableView.reloadData()
  }
}

