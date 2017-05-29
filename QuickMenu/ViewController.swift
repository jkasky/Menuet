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

    workspace = NSWorkspace.shared()
  }

  override func viewWillAppear() {
    let currentApp = workspace.frontmostApplication!
    let client = AX.Client()
    let axApp = client.createApplication(application:currentApp)
    let title: String? = axApp.topElement.get(.Title)
    guard title != nil else {
      return
    }
    NSLog(title!)
    NSLog("\(axApp.topElement.childCount)")
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }
}

