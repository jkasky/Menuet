//
//  Preferences.swift
//  Menuet
//
//

import KeyboardShortcuts
import SwiftUI


extension KeyboardShortcuts.Name {
  static let menuSearchShortcut = Self("menuSearchShortcut")
  static let cheatsheetShortcut = Self("cheatsheetShortcut")
}


extension UserDefaults  {

  var searchAppleMenu: Bool {
    get {
      return bool(forKey: "menuSearchAppleMenu")
    }
    set {
      setValue(newValue, forKey: "menuSearchAppleMenu")
    }
  }

  var searchCaseSensitive: Bool {
    get {
      return bool(forKey: "menuSearchCaseSensitive")
    }
    set {
      setValue(newValue, forKey: "menuSearchCaseSensitive")
    }
  }

  var showDisabledItems: Bool {
    get {
      return bool(forKey: "showDisabledItems")
    }
    set {
      setValue(newValue, forKey: "showDisabledItems")
    }
  }

  var requireShortcutToInvoke: Bool {
    get {
      return bool(forKey: "requireShortcutToInvoke")
    }
    set {
      setValue(newValue, forKey: "requireShortcutToInvoke")
    }
  }
}
