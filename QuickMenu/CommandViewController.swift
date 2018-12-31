//
//  ViewController.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 6/24/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Cocoa


class CommandViewController: NSViewController, NSTextDelegate {

  @IBOutlet
  weak var commandTextField: NSTextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.commandTextField.isBezeled = false
    self.commandTextField.isBordered = false
  }

  override func controlTextDidChange(_ notification: Notification) {
    SearchManager.shared.search(commandTextField.stringValue)
  }
}

