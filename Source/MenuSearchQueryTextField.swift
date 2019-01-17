//
//  MenuSearchQueryTextCell.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 2019-01-05.
//  Copyright © 2019 Codjax. All rights reserved.
//

import Cocoa
import Foundation


class MenuSearchQueryTextViewController: NSViewController, NSTextViewDelegate {
  
}


class MenuSearchQueryTextView: NSTextView {
  
  override func moveUp(_ sender: Any?) {
    NSLog("move up")
  }
  
  override func moveDown(_ sender: Any?) {
    NSLog("move down")
  }
}
