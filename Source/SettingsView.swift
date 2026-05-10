//
//  PreferencesWindow.swift
//  Menuet
//
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
  @AppStorage("menuSearchAppleMenu") private var searchAppleMenu = false
  @AppStorage("menuSearchMatchCase") private var matchCase = false
  @AppStorage("menuSearchShowDisabled") private var includeDisabled = false
  @AppStorage("requireShortcutToInvoke") private var requireShortcutToInvoke = true
  @AppStorage(Telemetry.crashReportingEnabledKey) private var crashReportingEnabled = true

  var body: some View {
    Form {
      Section(header: Text("Keyboard Shortcuts")) {
        KeyboardShortcuts.Recorder("Search", name: .menuSearchShortcut)
        KeyboardShortcuts.Recorder("Cheatsheet", name: .cheatsheetShortcut)
      }

      Section(header: Text("Search Options")) {
        Toggle(isOn: $searchAppleMenu) {
          Text("Search \(String(describing: KeyGlyph.Apple)) Apple menu")
        }
        .toggleStyle(.switch)

        Toggle(isOn: $matchCase) {
          Text("Match case")
        }
        .toggleStyle(.switch)

        Toggle(isOn: $includeDisabled) {
          Text("Include disabled menu items")
        }.toggleStyle(.switch)

        Toggle(isOn: $requireShortcutToInvoke) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Require shortcut to invoke")
            Text("When an item has a keyboard shortcut, press it to invoke. Helps you learn the shortcuts you actually use.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }.toggleStyle(.switch)
      }

      Section(header: Text("Privacy")) {
        Toggle(isOn: $crashReportingEnabled) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Send anonymous diagnostics")
            Text("Helps diagnose crashes and slow menu indexing. Sends macOS version, hardware model, app version, the bundle identifiers of apps you invoke Menuet against, and timing of accessibility calls. Does not send your name, email, or menu contents.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .toggleStyle(.switch)
        .onChange(of: crashReportingEnabled) { _, newValue in
          Telemetry.applySettingChange(enabled: newValue)
        }
      }
    }.formStyle(.grouped)
  }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
