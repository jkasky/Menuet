//
//  ViewController.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 6/24/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {

  @IBOutlet
  weak var commandTextField: NSTextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.commandTextField.bezeled = false
    self.commandTextField.bordered = false
  }

  override var representedObject: AnyObject? {
    didSet {
    // Update the view, if already loaded.
    }
  }
}

