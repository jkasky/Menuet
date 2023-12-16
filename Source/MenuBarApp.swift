import KeyboardShortcuts
import SwiftUI


@main
struct MenuBarApp: App {
  @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

  @StateObject private var searchManager = SearchManager.shared

  init() {
    // TODO: move this into a state object, migrate away from app delegate?
    KeyboardShortcuts.onKeyUp(for: .menuSearchShortcut) {
      NSApp.activate(ignoringOtherApps: true)
      NSApp.sendAction(Selector(("showSearchPanel")), to: nil, from: nil)
    }
  }

  var body: some Scene {
    // TODO: use the system image? loading StatusBarIcon not working
    // MenuBarExtra("MenuBarPro App", image: "StatusBarIcon") {
    MenuBarExtra("MenuBarPro App", systemImage: "menubar.rectangle") {

      Button("Search...") {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSearchPanel")), to: nil, from: nil)
      }

      Divider()

      if #available(macOS 14, *) {
        SettingsLink()
      } else {
        Button("Settings...") {
          NSApp.activate(ignoringOtherApps: true)
          NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
      }

      Divider()

      Button("Quit MenuBar Pro") {
        NSApp.terminate(nil)
      }
    }

    Settings() {
      SettingsView()
        .frame(
          minWidth: 400, maxWidth: 400,
          minHeight: 300, maxHeight: 300)
    }
    .defaultPosition(.center)
    .windowResizability(.contentSize)
  }
}
