//
//  PreferencesWindow.swift
//  Menuet
//
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
  @AppStorage(Preference.searchAppleMenu) private var searchAppleMenu = false
  @AppStorage(Preference.searchMatchCase) private var matchCase = false
  @AppStorage(Preference.searchShowDisabled) private var includeDisabled = false
  @AppStorage(Preference.requireShortcutToInvoke) private var requireShortcutToInvoke = true
  @AppStorage(Preference.crashReportingEnabled) private var crashReportingEnabled = true
  @State private var launchAtLogin = LaunchAtLogin.isEnabled

  var body: some View {
    Form {
      Section(header: Text("General")) {
        Toggle(isOn: $launchAtLogin) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Launch at login")
            Text("Start Menuet automatically when you sign in to your Mac.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .toggleStyle(.switch)
        .onChange(of: launchAtLogin) { _, newValue in
          do {
            try LaunchAtLogin.setEnabled(newValue)
          } catch {
            launchAtLogin = LaunchAtLogin.isEnabled
          }
        }
      }

      Section(header: Text("Keyboard Shortcuts")) {
        KeyboardShortcuts.Recorder("Search", name: .menuSearchShortcut)
        KeyboardShortcuts.Recorder("Cheatsheet", name: .cheatsheetShortcut)
      }

      Section(header: Text("Search Options")) {
        Toggle(isOn: $searchAppleMenu) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Search \(String(describing: KeyGlyph.Apple)) Apple menu")
            Text("Include items from the system menu (System Settings, Force Quit, Sleep) in results.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .toggleStyle(.switch)

        Toggle(isOn: $matchCase) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Match case")
            Text("Treat queries as case-sensitive. Off matches regardless of case.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .toggleStyle(.switch)

        Toggle(isOn: $includeDisabled) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Include disabled menu items")
            Text("Show items the app currently reports as disabled. Invoking them may do nothing.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
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
