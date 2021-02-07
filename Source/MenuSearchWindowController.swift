//
//  MenuSearchWindowController.swift
//  MenuFinder
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
  
  override var windowNibName: NSNib.Name? {
    get {
      return "MenuSearchWindow"
    }
  }
  
  func windowDidResignMain(_ notification: Notification) {
    if let item = SearchManager.shared.activeItem {
      item.command.perform()
    }
    SearchManager.shared.reset()

    // Always hide the window, may have been resigned because of focus change.
    hide()
  }
  
  override func windowWillLoad() {
    SearchEvent.ResultsChanged.observe(self, #selector(searchResultsDidChange))
  }

  @objc func searchResultsDidChange() {
    let searchManager = SearchManager.shared
    if var rect = window?.frame {
      if !searchManager.hasResults() && rect.size.height > 50 {
        rect.origin.y += 250
        rect.size.height = 50
        window?.setFrame(rect, display: false, animate: true)
      } else if searchManager.hasResults() && rect.size.height < 300 {
        rect.origin.y -= 250
        rect.size.height = 300
        window?.setFrame(rect, display: false, animate: true)
      }
    }
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
    if var frame = window?.frame {
      frame.size.height = 50
      window?.setFrame(frame, display: false, animate: false)
    }
    showWindow(nil)
    window?.center()
    window?.orderFrontRegardless()
  }
  
  func hide() {
    window?.orderOut(nil)
  }
  
  override func keyDown(with event: NSEvent) {
    interpretKeyEvents([event])
  }
  
  override func keyUp(with event: NSEvent) {
    if let key = event.characters?.unicodeScalars.first {
      switch Int(key.value) {
      case NSEvent.SpecialKey.downArrow.rawValue:
        moveDown(nil)
      case NSEvent.SpecialKey.upArrow.rawValue:
        moveUp(nil)
      case NSEvent.SpecialKey.carriageReturn.rawValue:
        insertNewline(nil)
      default:
        break
      }
    }
  }
  
  override func cancelOperation(_ sender: Any?) {
    // On `Escape` hide the window.
    hide()
  }
  
  override func insertNewline(_ sender: Any?) {
    // On `Enter` activate the selected menu item and hide the window. Once
    // the window resigns main the menu item will be performed. App owning the
    // menu bar may need to be main for the perform to take affect.
    SearchManager.shared.activateSelected()
    hide()
  }
  
  override func insertTab(_ sender: Any?) {
    searchResultsTableView.selectNextRow(nil)
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
