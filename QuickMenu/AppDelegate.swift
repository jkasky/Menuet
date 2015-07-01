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

  /**
   * Loads WindowController from Main storyboard.
   *
   * Instantiate the WindowController manually instead of relying on the
   * initial segue. The initial segue cannot be undone easily, manually
   * loading provides full control.
   */
  private func loadStoryboardResources() {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    windowController = storyboard?
      .instantiateControllerWithIdentifier("WindowController")
      as? CommandWindowController
  }

  /**
   * Activates the status menu item in the menu bar.
   */
  private func activateStatusMenu() {
    let statusBar = NSStatusBar.systemStatusBar()

    // Should be NSVariableStatusItemLength but produces a link error.
    statusItem = statusBar.statusItemWithLength(-1.0)
    
    // TODO: replace with icon
    statusItem!.button!.title = "QM"
    statusItem!.menu = statusMenu
  }

  /**
   * Removes the status menu item from the menu bar.
   */
  private func deactivateStatusMenu() {
    let statusBar = NSStatusBar.systemStatusBar()
    statusBar.removeStatusItem(statusItem!)
    statusItem = nil
  }

  /**
   * Registers the global hot key to show the command window.
   */
  private func registerHotKey() {
    let hotKeyMask: NSEventModifierFlags = .CommandKeyMask | .ShiftKeyMask
    hotKey = DDHotKeyCenter.sharedHotKeyCenter().registerHotKeyWithKeyCode(
      UInt16(kVK_Space),
      modifierFlags: hotKeyMask.rawValue,
      task: { _ in self.showCommandWindow() }
    )
    // TODO: if the hot key could not be registered display warning icon.
  }

  /**
   * Unregisters the global hot key to show the command window.
   */
  private func unregisterHotKey() {
    if (hotKey != nil) {
      DDHotKeyCenter.sharedHotKeyCenter().unregisterHotKey(hotKey)
    }
  }

  /**
   * Activates the application and show the command window.
   */
  private func showCommandWindow() {
    if (!application.active) {
      application.activateIgnoringOtherApps(true)
    }
    windowController!.showWindow(self)
  }

  @IBAction
  func show(sender: NSMenuItem) {
    showCommandWindow()
  }
}

