import KeyboardShortcuts
import SwiftUI


class AppState: ObservableObject {
  private var application: NSApplication = NSApplication.shared
  private var searchPanel: MenuSearchPanel?

  init() {
    initializeMenuResources()

    KeyboardShortcuts.onKeyUp(for: .menuSearchShortcut) {
      self.showSearchPanel()
    }

    makeProcessTrusted()
  }

  func activate() {
    if !application.isActive {
      application.activate()
    }
  }

  func showSearchPanel() {
    activate()
    if searchPanel == nil {
      searchPanel = MenuSearchPanel(contentRect: NSRect(x: 0, y: 0, width: 600, height: 50)) {
        MenuSearchView()
          .environmentObject(self)
          .environmentObject(SearchManager.shared)
      }
    }
    SearchManager.shared.activate()
    searchPanel?.center()
    searchPanel?.makeKeyAndOrderFront(nil)
  }

  private func makeProcessTrusted() {
    let axClient = AXClient()
    if (!axClient.isProcessTrusted()) {
      // TODO: the trusted state should be managed globally so the app can
      // check the state before showing the command window and re-prompt if
      // necessary.
      let trusted = axClient.makeProcessTrusted(withPrompt:true)
      if !trusted {
        NSLog("Process is not trusted.")
      }
    }
  }
}


@main
struct MenuBarApp: App {

  @StateObject private var appState = AppState()
  @StateObject private var searchManager = SearchManager.shared

  var body: some Scene {
    // TODO: use the system image? loading StatusBarIcon not working
    // MenuBarExtra("MenuBarPro App", image: "StatusBarIcon") {
    MenuBarExtra("MenuBarPro App", systemImage: "menubar.rectangle") {

      Button("Search...") {
        appState.showSearchPanel()
      }

      Divider()

      SettingsLink()

      Divider()

      Button("Quit MenuBar Pro") {
        NSApp.terminate(nil)
      }
    }
    .environmentObject(appState)

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
