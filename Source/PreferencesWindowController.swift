//
//  PreferencesWindowController.swift
//  Menumate
//
//  Created by Jesse Kasky on 2019-12-16.
//  Copyright © 2019 Codjax. All rights reserved.
//

import Cocoa
import Foundation
import ShortcutRecorder


class PreferencesWindowController: NSWindowController, NSWindowDelegate {
  
  override var windowNibName: NSNib.Name? {
    get {
      return "PreferencesWindow"
    }
  }
  
  func show() {
    showWindow(nil)
    window?.orderFrontRegardless()
  }
}

extension PreferencesWindowController: RecorderControlDelegate {

  func recorderControlDidBeginRecording(_ control: RecorderControl) {
    // Don't allow global hot keys while recording.
    HotKeyCenter.shared.disableAllHotKeys()
  }

  func recorderControlDidEndRecording(_ control: RecorderControl) {
    // Re-enable global hot keys since we are no longer recording.
    HotKeyCenter.shared.enableAllHotKeys()
  }
}
