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
import SwiftUI


class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

  let application = NSApplication.shared

  var searchPanel: MenuSearchPanel?
    
  @IBOutlet
  var searchMenuItem: NSMenuItem?

  var statusItem: NSStatusItem?
  
  var subscribers = Set<AnyCancellable>()
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    initializeMenuResources()
    initializeDefaults()
    makeProcessTrusted()
  }

  func applicationWillTerminate(_ notification: Notification) {
    subscribers.forEach { $0.cancel() }
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
    
//    if defaults.searchMenuShortcutValue == nil {
//      defaults.searchMenuShortcutValue = Shortcut(
//        code: KeyCode.space,
//        modifierFlags: [.command, .shift],
//        characters: " ",
//        charactersIgnoringModifiers: " ")
//    }
    
    // Watch for changes to search menu shortcut, re-register on changes.
    // This KVO is triggered immediately and will setup the initial hot key.
//    defaults
//      .publisher(for: \.searchMenuShortcut)
//      .sink { _ in self.registerSearchMenuHotKey() }
//      .store(in: &subscribers)
  }

  /**
   * Registers global hot key to show the search window.
   */
  private func registerSearchMenuHotKey() {
//    guard let searchMenuShorcut = UserDefaults.standard.searchMenuShortcutValue else { return }
//    showMenuSearchWindowHotKey.map { hotKeyCenter.unregister($0) }
//    showMenuSearchWindowHotKey = HotKey(Int(searchMenuShorcut.keyCode.rawValue), searchMenuShorcut.modifierFlags) {
//      _ in self.showMenuSearchWindow()
//    }
//    showMenuSearchWindowHotKey.map {
//      hotKeyCenter.register($0)
//      if let item = searchMenuItem {
//        item.keyEquivalent = searchMenuShorcut.characters ?? ""
//        item.keyEquivalentModifierMask = searchMenuShorcut.modifierFlags
//      }
//    }
  }

  /**
   * Makes this process trusted for accessibility access.
   */
  private func makeProcessTrusted() {
    let axClient = AXClient()
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

  @objc func showSearchPanel() {
    if searchPanel == nil {
      searchPanel = MenuSearchPanel(contentRect: NSRect(x: 0, y: 0, width: 600, height: 50)) {
        MenuSearchView().environmentObject(SearchManager.shared)
      }
    }
    SearchManager.shared.activate()
    searchPanel?.center()
    searchPanel?.makeKeyAndOrderFront(nil)
  }
}

