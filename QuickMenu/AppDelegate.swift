//
//  AppDelegate.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 6/24/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  @IBOutlet
  var statusMenu: NSMenu?
  
  var statusItem: NSStatusItem?

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    activateStatusMenu()
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    deactivateStatusMenu()
  }

  private func activateStatusMenu() {
    let statusBar = NSStatusBar.systemStatusBar()

    // Should be NSVariableStatusItemLength but produces a link error.
    statusItem = statusBar.statusItemWithLength(-1.0)
    
    // TODO: replace with icon
    statusItem!.button!.title = "QM"
    statusItem!.menu = statusMenu
  }
  
  private func deactivateStatusMenu() {
    let statusBar = NSStatusBar.systemStatusBar()
    statusBar.removeStatusItem(statusItem!)
    statusItem = nil
  }

}

