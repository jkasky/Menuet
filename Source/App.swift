import KeyboardShortcuts
import OSLog
import SwiftUI


private let logger = Logger(subsystem: "app.menuet", category: "app")


@Observable
@MainActor
final class AppState {
  let menus: IndexProvider
  let search: SearchSession
  let cheatsheet: CheatsheetSession

  private var application: NSApplication = NSApplication.shared
  private var searchPanel: SearchPanel?
  private var cheatsheetPanel: CheatsheetPanel?

  init(menus: IndexProvider, search: SearchSession, cheatsheet: CheatsheetSession) {
    self.menus = menus
    self.search = search
    self.cheatsheet = cheatsheet

    // KeyboardShortcuts dispatches the callback on main; assumeIsolated
    // bridges the non-isolated closure into our @MainActor methods.
    KeyboardShortcuts.onKeyUp(for: .menuSearchShortcut) {
      MainActor.assumeIsolated { self.showSearchPanel() }
    }

    KeyboardShortcuts.onKeyUp(for: .cheatsheetShortcut) {
      MainActor.assumeIsolated { self.showCheatsheetPanel() }
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
    menus.refresh()
    search.clear()
    activate()
    if searchPanel == nil {
      searchPanel = SearchPanel(
        contentRect: NSRect(x: 0, y: 0, width: 600, height: 50),
        menus: menus,
        search: search
      ) { [search, menus] in
        SearchView()
          .environment(search)
          .environment(menus)
      }
    }
    searchPanel?.center()
    searchPanel?.makeKeyAndOrderFront(nil)
    DispatchQueue.main.async { [search] in
      search.focusTrigger.toggle()
    }
  }

  func showCheatsheetPanel() {
    // Walk first, then activate, so the target app's menu items aren't
    // disabled in response to resigning key/first-responder.
    menus.refresh()
    cheatsheet.load()
    activate()
    if cheatsheetPanel == nil {
      cheatsheetPanel = CheatsheetPanel(
        contentRect: NSRect(x: 0, y: 0, width: 1100, height: 720),
        menus: menus,
        cheatsheet: cheatsheet
      ) { [cheatsheet, menus] in
        CheatsheetView()
          .environment(cheatsheet)
          .environment(menus)
      }
    }
    cheatsheetPanel?.positionAtTop()
    cheatsheetPanel?.makeKeyAndOrderFront(nil)
    DispatchQueue.main.async { [cheatsheet] in
      cheatsheet.resetTrigger.toggle()
    }
  }

  private func makeProcessTrusted() {
    // Triggers Apple's first-launch Accessibility prompt. After grant,
    // subsequent revoke/regrant cycles are detected by
    // `IndexProvider.refresh`, which re-checks trust on every panel
    // open and surfaces `NeedsAccessibilityView` when false.
    let axClient = AXClient()
    if !axClient.isProcessTrusted() {
      let trusted = axClient.makeProcessTrusted(withPrompt: true)
      if !trusted {
        logger.warning("Process is not trusted; AX queries will return nothing until granted.")
      }
    }
  }
}


struct MenuBarContent: View {
  @Environment(AppState.self) private var appState
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
      NSApp.activate()
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

  @State private var appState: AppState

  init() {
    registerPreferenceDefaults()
    Telemetry.startIfEnabled()
    let menus = IndexProvider()
    let search = SearchSession(menus: menus)
    let cheatsheet = CheatsheetSession(menus: menus)
    _appState = State(initialValue: AppState(menus: menus, search: search, cheatsheet: cheatsheet))
  }

  var body: some Scene {
    MenuBarExtra("Menuet", systemImage: "menubar.rectangle") {
      MenuBarContent()
        .environment(appState)
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
