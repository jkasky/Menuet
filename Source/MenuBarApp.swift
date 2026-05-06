import KeyboardShortcuts
import SwiftUI


class AppState: ObservableObject {
  private var application: NSApplication = NSApplication.shared
  private var searchPanel: MenuSearchPanel?
  private var cheatsheetPanel: MenuCheatsheetPanel?

  init() {
    initializeMenuResources()

    KeyboardShortcuts.onKeyUp(for: .menuSearchShortcut) {
      self.showSearchPanel()
    }

    KeyboardShortcuts.onKeyUp(for: .cheatsheetShortcut) {
      self.showCheatsheetPanel()
    }

    makeProcessTrusted()
  }

  func activate() {
    if !application.isActive {
      application.activate()
    }
  }

  func showSearchPanel() {
    // Walk the target app's menu BEFORE we activate or take key window,
    // so menu items aren't disabled by the target app in response to
    // resigning key/first-responder.
    SearchManager.shared.activate()
    activate()
    if searchPanel == nil {
      searchPanel = MenuSearchPanel(contentRect: NSRect(x: 0, y: 0, width: 600, height: 50)) {
        MenuSearchView()
          .environmentObject(self)
          .environmentObject(SearchManager.shared)
      }
    }
    searchPanel?.center()
    searchPanel?.makeKeyAndOrderFront(nil)
    DispatchQueue.main.async {
      SearchManager.shared.focusTrigger.toggle()
    }
  }

  func showCheatsheetPanel() {
    // Walk first, then activate, so the target app's menu items aren't
    // disabled in response to resigning key/first-responder.
    SearchManager.shared.activate()
    SearchManager.shared.loadCheatsheetGroups()
    activate()
    if cheatsheetPanel == nil {
      cheatsheetPanel = MenuCheatsheetPanel(
        contentRect: NSRect(x: 0, y: 0, width: 1100, height: 720)
      ) {
        MenuCheatsheetView()
          .environmentObject(self)
          .environmentObject(SearchManager.shared)
      }
    }
    cheatsheetPanel?.positionAtTop()
    cheatsheetPanel?.makeKeyAndOrderFront(nil)
    DispatchQueue.main.async {
      SearchManager.shared.cheatsheetResetTrigger.toggle()
    }
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


struct MenuBarContent: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.openSettings) private var openSettings

  var body: some View {
    Button("Search...") {
      appState.showSearchPanel()
    }

    Button("Cheatsheet...") {
      appState.showCheatsheetPanel()
    }

    Divider()

    Button("Settings...") {
      NSApp.activate(ignoringOtherApps: true)
      openSettings()
    }

    Divider()

    Button("Quit Menuet") {
      NSApp.terminate(nil)
    }
  }
}

@main
struct MenuBarApp: App {

  @StateObject private var appState = AppState()
  @StateObject private var searchManager = SearchManager.shared

  var body: some Scene {
    // TODO: use the system image? loading StatusBarIcon not working
    // MenuBarExtra("Menuet", image: "StatusBarIcon") {
    MenuBarExtra("Menuet", systemImage: "menubar.rectangle") {
      MenuBarContent()
        .environmentObject(appState)
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
