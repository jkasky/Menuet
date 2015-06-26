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

  let application = NSApplication.sharedApplication()

  @IBOutlet
  var statusMenu: NSMenu?

  var statusItem: NSStatusItem?
  var windowController: CommandWindowController?

  func applicationDidFinishLaunching(notification: NSNotification) {
    loadStoryboardResources()
    activateStatusMenu()
  }

  func applicationWillTerminate(notification: NSNotification) {
    deactivateStatusMenu()
  }

  private func loadStoryboardResources() {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    windowController = storyboard?
      .instantiateControllerWithIdentifier("WindowController")
      as? CommandWindowController
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

  @IBAction
  func showWindow(sender: NSMenuItem) {
    if (!application.active) {
      application.activateIgnoringOtherApps(true)
    }
    windowController!.showWindow(sender)
  }
}

