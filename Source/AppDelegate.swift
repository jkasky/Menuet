//
//  AppDelegate.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 6/24/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Carbon
import Cocoa
import Combine
import ShortcutRecorder


class AppDelegate: NSObject, NSApplicationDelegate {

  let application = NSApplication.shared
  let hotKeyCenter = HotKeyCenter.shared

  var menuSearchWindowController: MenuSearchWindowController?
  var showMenuSearchWindowHotKey: HotKey?
  var preferencesWindowController: PreferencesWindowController?
  
  @IBOutlet
  var statusMenu: NSMenu?
  
  @IBOutlet
  var searchMenuItem: NSMenuItem?

  var statusItem: NSStatusItem?
  
  var subscribers = Set<AnyCancellable>()
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    initializeMenuResources()
    initializeDefaults()
    activateStatusMenu()
    makeProcessTrusted()
  }

  func applicationWillTerminate(_ notification: Notification) {
    subscribers.forEach { $0.cancel() }
    unregisterHotKeys()
    deactivateStatusMenu()
  }
  
  private func initializeDefaults() {
    let defaults = UserDefaults.standard
    
    #if DEBUG
    defaults.set(
      true,
      forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
    #else
    defaults.removeObject(
      forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
    #endif
    
    if defaults.searchMenuShortcutValue == nil {
      defaults.searchMenuShortcutValue = Shortcut(
        code: KeyCode.space,
        modifierFlags: [.command, .shift],
        characters: " ",
        charactersIgnoringModifiers: " ")
    }
    
    // Watch for changes to search menu shortcut, re-register on changes.
    // This KVO is triggered immediately and will setup the initial hot key.
    defaults
      .publisher(for: \.searchMenuShortcut)
      .sink { _ in self.registerSearchMenuHotKey() }
      .store(in: &subscribers)
  }

  /**
   * Activates the status menu item in the menu bar.
   */
  private func activateStatusMenu() {
    let statusBar = NSStatusBar.system
    statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
    let icon = NSImage(named: "StatusBarIcon")
    icon?.isTemplate = true
    statusItem!.button!.image = icon
    statusItem!.button!.imageScaling = .scaleProportionallyUpOrDown
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
   * Registers global hot key to show the search window.
   */
  private func registerSearchMenuHotKey() {
    guard let searchMenuShorcut = UserDefaults.standard.searchMenuShortcutValue else { return }
    showMenuSearchWindowHotKey.map { hotKeyCenter.unregister($0) }
    showMenuSearchWindowHotKey = HotKey(Int(searchMenuShorcut.keyCode.rawValue), searchMenuShorcut.modifierFlags) {
      _ in self.showMenuSearchWindow()
    }
    showMenuSearchWindowHotKey.map {
      hotKeyCenter.register($0)
      if let item = searchMenuItem {
        item.keyEquivalent = searchMenuShorcut.characters ?? ""
        item.keyEquivalentModifierMask = searchMenuShorcut.modifierFlags
      }
    }
  }

  /**
   * Unregisters all global hot keys.
   */
  private func unregisterHotKeys() {
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
   * Activates the application and show the menu search window.
   */
  private func showMenuSearchWindow() {
    if menuSearchWindowController == nil {
      menuSearchWindowController = MenuSearchWindowController(window: nil)
    }
    menuSearchWindowController!.show()
  }

  /**
   * Handles the show `menu` action.
   */
  @IBAction
  func show(_ sender: NSMenuItem) {
    showMenuSearchWindow()
  }
  
  /**
   * Handles the `preferences` action.
   */
  @IBAction
  func preferences(_ sender: NSMenuItem) {
    if preferencesWindowController == nil {
      preferencesWindowController = PreferencesWindowController(window: nil)
    }
    preferencesWindowController?.show()
  }
}

