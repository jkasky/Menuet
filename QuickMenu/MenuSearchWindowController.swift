//
//  MenuSearchWindowController.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 2019-01-05.
//  Copyright © 2019 Codjax. All rights reserved.
//

import Cocoa
import Foundation


class MenuSearchWindowController: NSWindowController, NSWindowDelegate {
  
  @IBOutlet
  weak var searchResultsTableView: NSTableView!
  
  var menuSearchQueryFieldEditor: MenuSearchQueryTextFieldEditor?
  
  override func windowDidLoad() {
    window?.canHide = true
    window?.collectionBehavior = .moveToActiveSpace
    window?.hasShadow = true
    window?.level = .floating
    window?.isOpaque = true
  }
  
  func windowDidResignMain(_ notification: Notification) {
    hide()
  }
  
  func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
    if client is NSTextField {
      if menuSearchQueryFieldEditor == nil {
        let textField = client as! NSTextField
        menuSearchQueryFieldEditor = MenuSearchQueryTextFieldEditor(
          frame: textField.frame)
        menuSearchQueryFieldEditor?.isFieldEditor = true
      }
      return menuSearchQueryFieldEditor
    }
    return nil
  }
  
  func show() {
    showWindow(nil)
    window?.orderFrontRegardless()
  }
  
  func hide() {
    window?.orderOut(nil)
  }
  
  override func keyDown(with event: NSEvent) {
    interpretKeyEvents([event])
  }
  
  override func keyUp(with event: NSEvent) {
    interpretKeyEvents([event])
  }
  
  override func cancelOperation(_ sender: Any?) {
    // On `Escape` @objc hide the window.
    hide()
  }
  
  override func insertNewline(_ sender: Any?) {
    // On `Enter` perform the selected menu item command.
    SearchManager.shared.performSelected()
    hide()
  }
  
  override func moveDown(_ sender: Any?) {
    // On `Arrow Down` select the next row in the search results.
    searchResultsTableView.selectNextRow(nil)
  }
  
  override func moveUp(_ sender: Any?) {
    // On `Arrow Up` select the previous row in the search results.
    searchResultsTableView.selectPreviousRow(nil)
  }
}
