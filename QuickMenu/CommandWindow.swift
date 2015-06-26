//
//  CommandWindow.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 6/26/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Cocoa


class CommandWindow: NSWindow {

  // Override canBecome{Key,Main}Window to always return True. The default
  // behavior by NSWindow is to not allow windows without title bars to become
  // key or main window.
  override var canBecomeKeyWindow: Bool {
    return true;
  }

  override var canBecomeMainWindow: Bool {
    return true;
  }
}


class CommandWindowController: NSWindowController {

  override func windowDidLoad() {
    self.window!.canHide = true
    self.window!.collectionBehavior = .MoveToActiveSpace
    self.window!.hasShadow = true
    self.window!.hidesOnDeactivate = true
    self.window!.opaque = true
  }
}