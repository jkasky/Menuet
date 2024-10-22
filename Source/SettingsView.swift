import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
  @AppStorage("menuSearchAppleMenu") private var searchAppleMenu = false
  @AppStorage("menuSearchMatchCase") private var matchCase = false
  @AppStorage("menuSearchShowDisabled") private var includeDisabled = false

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
      }

      Section(header: Text("Cheatsheet Panel")) {
        Button("Show Cheatsheet Panel") {
          NSApp.activate(ignoringOtherApps: true)
          NSApp.sendAction(#selector(AppDelegate.showCheatsheetPanel), to: nil, from: nil)
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
