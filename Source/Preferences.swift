//
//  Preferences.swift
//  Menuet
//
//  Single source of truth for UserDefaults keys, registered defaults,
//  and the typed accessors used throughout the app.
//

import KeyboardShortcuts
import SwiftUI


enum Preference {
  // User-facing toggles. These are covered by registerPreferenceDefaults.
  static let searchAppleMenu        = "menuSearchAppleMenu"
  static let searchMatchCase        = "menuSearchMatchCase"
  static let searchShowDisabled     = "menuSearchShowDisabled"
  static let requireShortcutToInvoke = "requireShortcutToInvoke"
  static let crashReportingEnabled  = "crashReportingEnabled"

  // Developer overrides — set via `defaults write app.menuet …`.
  // Intentionally NOT covered by registerPreferenceDefaults: as
  // the actual default is hard coded.
  static let axMessagingTimeout = "axMessagingTimeout"
  static let axWalkDeadline     = "axWalkDeadline"
}


/// Populates the UserDefaults registration domain with every default
/// for keys the app reads. Call once at app launch (MenuBarApp.init)
/// before any preference is consulted.
func registerPreferenceDefaults() {
  UserDefaults.standard.register(defaults: [
    Preference.searchAppleMenu:         false,
    Preference.searchMatchCase:         false,
    Preference.searchShowDisabled:      false,
    Preference.requireShortcutToInvoke: true,
    Preference.crashReportingEnabled:   true,
  ])
}


extension KeyboardShortcuts.Name {
  static let menuSearchShortcut = Self("menuSearchShortcut")
  static let cheatsheetShortcut = Self("cheatsheetShortcut")
}


extension UserDefaults {

  var searchAppleMenu: Bool {
    bool(forKey: Preference.searchAppleMenu)
  }

  var searchMatchCase: Bool {
    bool(forKey: Preference.searchMatchCase)
  }

  var showDisabledItems: Bool {
    bool(forKey: Preference.searchShowDisabled)
  }

  var requireShortcutToInvoke: Bool {
    bool(forKey: Preference.requireShortcutToInvoke)
  }
}
