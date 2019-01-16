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
  
  var searchManager: SearchManager!

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
    searchManager.clear()
    queryField.stringValue = ""
    searchMenuResultsTableView.reloadData()
  }

  override func controlTextDidChange(_ notification: Notification) {
    searchManager.search(queryField.stringValue)
    searchMenuResultsTableView.reloadData()
    if var rect = view.window?.frame {
      if searchManager.searchResults.isEmpty && rect.size.height >= 50 {
        rect.origin.y += 250
        rect.size.height = 50
        view.window?.setFrame(rect, display: false, animate: true)
      } else if !searchManager.searchResults.isEmpty && rect.size.height < 300 {
        rect.origin.y -= 250
        rect.size.height = 300
        view.window?.setFrame(rect, display: false, animate: true)
      }
    }
  }
}

