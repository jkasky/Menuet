//
//  CommandWindow.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 6/26/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Cocoa


class MenuSearchContentView: NSView {
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  override func updateLayer() {
    layer?.cornerRadius = 10.0
    layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    super.updateLayer()
  }
}


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
  
  override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask,
                backing backingStoreType: NSWindow.BackingStoreType,
                defer flag: Bool) {
    super.init(contentRect: contentRect, styleMask: style,
               backing: backingStoreType, defer: flag)
    canHide = true
    collectionBehavior = .moveToActiveSpace
    hasShadow = true
    level = .floating
    
    // Use clear translucent background so the content view can be used to
    // render a panel with rounded corners similar to the spotlight search
    // panel.
    backgroundColor = NSColor.clear
    isOpaque = false
  }
}
