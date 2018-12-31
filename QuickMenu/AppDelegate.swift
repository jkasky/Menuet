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

  let application = NSApplication.shared
  let hotKeyCenter = HotKeyCenter.shared
  let commandWindowNib = NSNib.Name("CommandWindow")

  var commandWindow: CommandWindowController?
  
  @IBOutlet
  var statusMenu: NSMenu?

  var statusItem: NSStatusItem?

  func applicationDidFinishLaunching(_ notification: Notification) {
    initializeMenuResources()
    activateStatusMenu()
    registerHotKey()
    makeProcessTrusted()
  }

  func applicationWillTerminate(_ notification: Notification) {
    unregisterHotKey()
    deactivateStatusMenu()
  }

  /**
   * Activates the status menu item in the menu bar.
   */
  private func activateStatusMenu() {
    let statusBar = NSStatusBar.system

    // Should be NSVariableStatusItemLength but produces a link error.
    statusItem = statusBar.statusItem(withLength: -1.0)
    
    // TODO: replace with icon
    statusItem!.button!.title = "QM"
    statusItem!.menu = statusMenu
  }

  /**
   * Removes the status menu item from the menu bar.
   */
  private func deactivateStatusMenu() {
    let statusBar = NSStatusBar.system
    statusBar.removeStatusItem(statusItem!)
    statusItem = nil
  }

  /**
   * Registers the global hot key to show the command window.
   */
  private func registerHotKey() {
    let showCommandWindowHotKey = HotKey(kVK_Space, [.command, .shift]) {
      _ in self.showCommandWindow()
    }
    hotKeyCenter.register(showCommandWindowHotKey)
  }

  /**
   * Unregisters the global hot key to show the command window.
   */
  private func unregisterHotKey() {
    hotKeyCenter.unregisterAll()
  }

  /**
   * Makes this process trusted for accessibility access.
   */
  private func makeProcessTrusted() {
    let axClient = AX.Client()
    if (!axClient.isProcessTrusted()) {
      // TODO: the trusted state should be managed globally so the app can
      // check the state before showing the command window and re-prompt if
      // necessary.
      let trusted = axClient.makeProcessTrusted(withPrompt:true)
      if !trusted {
        NSLog("Process is not trusted.")
      }
    }
  }

  /**
   * Activates the application and show the command window.
   */
  private func showCommandWindow() {
    if commandWindow == nil {
      commandWindow = CommandWindowController(windowNibName: commandWindowNib)
    }
    commandWindow!.show()
  }

  /**
   * Handles the show `menu` action.
   */
  @IBAction
  func show(_ sender: NSMenuItem) {
    showCommandWindow()
  }
}

