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

  @IBOutlet
  var statusMenu: NSMenu?

  var hotKey: DDHotKey?
  var statusItem: NSStatusItem?
  var windowController: CommandWindowController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    loadStoryboardResources()
    activateStatusMenu()
    registerHotKey()
    makeProcessTrusted()
  }

  func applicationWillTerminate(_ notification: Notification) {
    unregisterHotKey()
    deactivateStatusMenu()
  }

  /**
   * Loads WindowController from Main storyboard.
   */
  private func loadStoryboardResources() {
    let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
    windowController = storyboard
      .instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "WindowController"))
      as? CommandWindowController
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
    let hotKeyMask: NSEvent.ModifierFlags = [NSEvent.ModifierFlags.command, NSEvent.ModifierFlags.shift]
    hotKey = DDHotKeyCenter.shared().registerHotKey(
      withKeyCode: UInt16(kVK_Space),
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
      DDHotKeyCenter.shared().unregisterHotKey(hotKey)
    }
  }

  /**
   * Makes this process trusted for accessibility access.
   */
  private func makeProcessTrusted() {
    let axClient = AX.Client()
    if (!axClient.isProcessTrusted()) {
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
    let workspace = NSWorkspace.shared
    let currentApp = workspace.frontmostApplication!
    let client = AX.Client()
    let axApp = client.createApplication(application:currentApp)
    let walker = AXMenuWalker(application: axApp.topElement)
    walker.walk(visitor: AXMenuLogger())

    windowController!.showWindow(self)
  }

  /**
   * Handles the show `menu` action.
   */
  @IBAction
  func show(_ sender: NSMenuItem) {
    showCommandWindow()
  }
}

