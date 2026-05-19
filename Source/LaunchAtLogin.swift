//
//  LaunchAtLogin.swift
//  Menuet
//
//  Thin wrapper around SMAppService.mainApp so the Settings toggle
//  can register/unregister Menuet as a login item. The system is
//  the source of truth — there is no mirrored UserDefaults key.
//

import ServiceManagement

enum LaunchAtLogin {
  static var isEnabled: Bool {
    SMAppService.mainApp.status == .enabled
  }

  static func setEnabled(_ enabled: Bool) throws {
    if enabled {
      try SMAppService.mainApp.register()
    } else {
      try SMAppService.mainApp.unregister()
    }
  }
}
