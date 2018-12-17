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

  var workspace: NSWorkspace!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.commandTextField.isBezeled = false
    self.commandTextField.isBordered = false

    workspace = NSWorkspace.shared
  }

  override func viewWillAppear() {
    super.viewWillAppear()
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
  }
}

