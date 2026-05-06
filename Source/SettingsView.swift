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
    }.formStyle(.grouped)
  }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
