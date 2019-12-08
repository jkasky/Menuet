//
//  MenuSearchQueryTextView.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 2019-01-05.
//  Copyright © 2019 Codjax. All rights reserved.
//

import Cocoa
import Foundation


class MenuSearchQueryTextFieldEditor: NSTextView {
  
  // Disable the normal text view handling of the up and down arrow keys that
  // moves the cursor to the beginning or end of the text field. The moveUp
  // and moveDown are handled by the window controller and allow navigation of
  // the search results without losing the focus in the text field.

  override func moveUp(_ sender: Any?) {}
  
  override func moveDown(_ sender: Any?) {}
  
  override func insertTab(_ sender: Any?) {
    NSLog("tab")
  }
  
  override func insertBacktab(_ sender: Any?) {
    NSLog("backtab")
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    let searchManager = SearchManager.shared
    if let quickIndex = Int(event.charactersIgnoringModifiers!) {
      if quickIndex > 0 && quickIndex < 8 {
        let row = quickIndex - 1
        searchManager.getResult(at: row).command.perform();
        NSApp.mainWindow?.orderOut(nil)
        return true
      }
    }
    return super.performKeyEquivalent(with:event)
  }
}
