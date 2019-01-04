//
//  CommandWindow.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 6/26/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Carbon
import Cocoa


class MenuSearchWindow: NSPanel {

  // Override canBecome{Key,Main}Window to always return True. The default
  // behavior by NSWindow is to not allow windows without title bars to become
  // key or main window.
  override var canBecomeKey: Bool {
    return true;
  }

  override var canBecomeMain: Bool {
    return true;
  }
  
  override func keyDown(with event: NSEvent) {
    interpretKeyEvents([event])
  }
  
  override func cancelOperation(_ sender: Any?) {
    // On `Escape` hide the window.
    orderOut(nil)
  }
  
  override func insertNewline(_ sender: Any?) {
    // On `Enter` perform the selected menu item command.
    SearchManager.shared.performSelected()
    orderOut(nil)
  }
  
  override func moveDown(_ sender: Any?) {
    NSLog("move down")
  }
  
  override func moveUp(_ sender: Any?) {
    NSLog("move up")
  }
}

class MenuSearchWindowController: NSWindowController, NSWindowDelegate {

  override func windowDidLoad() {
    window?.canHide = true
    window?.collectionBehavior = .moveToActiveSpace
    window?.hasShadow = true
    window?.level = .floating
    window?.isOpaque = true
  }
  
  func windowDidResignMain(_ notification: Notification) {
    hide()
  }
  
  func show() {
    showWindow(nil)
    window?.orderFrontRegardless()
  }
  
  func hide() {
    window?.orderOut(nil)
  }
}
