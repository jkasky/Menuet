//
//  AppDelegate.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 6/24/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Carbon
import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  let application = NSApplication.sharedApplication()

  @IBOutlet
  var statusMenu: NSMenu?

  var hotKey: DDHotKey?
  var statusItem: NSStatusItem?
  var windowController: CommandWindowController?

  func applicationDidFinishLaunching(notification: NSNotification) {
    loadStoryboardResources()
    activateStatusMenu()
    registerHotKey()
  }

  func applicationWillTerminate(notification: NSNotification) {
    deactivateStatusMenu()
    unregisterHotKey()
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

  private func registerHotKey() {
    let hotKeyHandler: DDHotKeyTask = { event in self.showCommandWindow() }
    let hotKeyCenter = DDHotKeyCenter.sharedHotKeyCenter()
    let hotKeyMask: NSEventModifierFlags = .CommandKeyMask | .ShiftKeyMask
    hotKey = hotKeyCenter.registerHotKeyWithKeyCode(
      UInt16(kVK_Space),
      modifierFlags: hotKeyMask.rawValue,
      task: hotKeyHandler
    )
  }

  private func unregisterHotKey() {
    let hotKeyCenter = DDHotKeyCenter.sharedHotKeyCenter()
    if (hotKey != nil) {
      hotKeyCenter.unregisterHotKey(hotKey)
    }
  }

  private func showCommandWindow() {
    if (!application.active) {
      application.activateIgnoringOtherApps(true)
    }
    windowController!.showWindow(self)
  }

  @IBAction
  func show(sender: NSMenuItem) {
    self.showCommandWindow()
  }
}

