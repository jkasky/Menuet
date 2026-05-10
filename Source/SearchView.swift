//
//  MenuSearchView.swift
//  Menuet
//
//

import Carbon.HIToolbox
import SwiftUI

enum SearchKeyAction {
  case next
  case previous
  case invoke
}

struct PendingSearchAction: Equatable {
  let action: SearchKeyAction
  let id = UUID()

  static func == (lhs: PendingSearchAction, rhs: PendingSearchAction) -> Bool {
    lhs.id == rhs.id
  }
}

struct SearchView: View {
  @EnvironmentObject var search: SearchSession
  @EnvironmentObject var menus: IndexProvider
  // .onKeyPress fires inside a SwiftUI view update, so mutating @Published
  // state directly there triggers "Publishing changes from within view
  // updates is not allowed". Instead we record the intent in @State and
  // perform the mutation in .onChange, which runs between update cycles.
  // Each press gets a fresh UUID so repeated identical actions still
  // trigger .onChange (key-repeat correctness).
  @State private var pendingAction: PendingSearchAction?

  private var showNotResponding: Bool {
    !menus.index.isComplete && menus.index.isEmpty
  }

  var body: some View {
    PanelBackground {
      VStack(alignment: .leading, spacing: 0) {
        SearchField()
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        if showNotResponding {
          Divider().opacity(0.4)
          NotRespondingView(appName: menus.currentApp?.localizedName ?? "This app")
            .frame(minHeight: 140)
        } else if !search.searchResults.isEmpty {
          Divider().opacity(0.4)
          ResultsView()
          Divider().opacity(0.4)
          FooterHintView()
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
      }
    }
    .frame(minWidth: 600, maxWidth: 600, minHeight: 40, maxHeight: 500)
    .fixedSize()
    // Intercept arrows / Return at the focus-tree ancestor so they fire while
    // the TextField holds focus. SwiftUI delivers ancestor .onKeyPress before
    // the field editor's text-navigation actions for these keys. We read
    // NSApp.currentEvent because KeyPress.key doesn't reliably carry keyCode
    // across keyboard layouts (the Maccy approach).
    .onKeyPress(phases: [.down, .repeat]) { _ in handleKeyPress() }
    .onChange(of: pendingAction) { _, pending in
      guard let pending else { return }
      performAction(pending.action)
    }
  }

  private func handleKeyPress() -> KeyPress.Result {
    // Pass through while IME composition is active so candidate selection works.
    if let inputClient = NSApp.keyWindow?.firstResponder as? NSTextInputClient,
       inputClient.hasMarkedText() {
      return .ignored
    }
    guard let event = NSApp.currentEvent else { return .ignored }

    switch Int(event.keyCode) {
    case kVK_DownArrow:
      pendingAction = PendingSearchAction(action: .next)
      return .handled
    case kVK_UpArrow:
      pendingAction = PendingSearchAction(action: .previous)
      return .handled
    case kVK_Return, kVK_ANSI_KeypadEnter:
      pendingAction = PendingSearchAction(action: .invoke)
      return .handled
    default:
      return .ignored
    }
  }

  private func performAction(_ action: SearchKeyAction) {
    switch action {
    case .next:
      search.selectNext()
    case .previous:
      search.selectPrevious()
    case .invoke:
      guard let item = search.activeItem else { return }
      let hasShortcut = !item.command.stringValue.isEmpty
      if hasShortcut && UserDefaults.standard.requireShortcutToInvoke {
        search.blockedReturnPulse += 1
      } else if let panel = NSApp.keyWindow as? SearchPanel {
        panel.dismissAndPerform(item.command)
      }
    }
  }
}

struct MenuSearchView_Previews: PreviewProvider {
    static var previews: some View {
      let menus = IndexProvider()
      let search = SearchSession(menus: menus)
      search.query = "About"
      return SearchView()
        .environmentObject(search)
        .environmentObject(menus)
    }
}

struct AppIcon: View {
  @EnvironmentObject var menus: IndexProvider
  private var placeholder = Image(systemName: "app")

  var body: some View {
    if let icon = menus.currentApp?.icon {
      Image(nsImage: icon)
        .resizable()
        .interpolation(.high)
        .frame(width: 48, height: 48)
    } else {
      placeholder
        .frame(width: 48, height: 48)
    }
  }
}

struct SearchField: View {
  @EnvironmentObject var search: SearchSession
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack(spacing: 10) {
      AppIcon()
      TextField("Menu Search", text: $search.query)
        .font(.system(.title2, design: .rounded))
        .textFieldStyle(.plain)
        .focused($isFocused)
      if !search.query.isEmpty {
        Text("\(search.searchResults.count) \(search.searchResults.count == 1 ? "match" : "matches")")
          .font(.system(.subheadline, design: .rounded))
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }
    }
    .onChange(of: search.focusTrigger) {
      isFocused = true
    }
    .onReceive(
      search.$query.debounce(for: .seconds(0.4), scheduler: DispatchQueue.main)
    ) { q in
      search.search(q)
    }
  }
}


struct ResultsView: View {
  @EnvironmentObject var search: SearchSession

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 2) {
          ForEach($search.searchResults.indices, id: \.self) { index in
            ResultView(result: $search.searchResults[index])
              .frame(maxWidth: .infinity, alignment: .leading)
              .id(search.searchResults[index].id)
          }
        }
        .frame(
          minWidth: 0.0,
          maxWidth: .infinity,
          minHeight: 0.0,
          maxHeight: .infinity,
          alignment: .topLeading
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
      }
      .frame(maxHeight: 500.0)
      .onReceive(search.$activeItem) { activeItem in
        if let item = activeItem {
          proxy.scrollTo(item.id)
        }
      }
    }
  }
}

struct ResultView: View {
  @EnvironmentObject var search: SearchSession
  @Binding var result: MenuItem
  @State private var hovering: Bool = false
  @State private var chipScale: CGFloat = 1.0
  @AppStorage("requireShortcutToInvoke") private var requireShortcutToInvoke = true

  private var isActive: Bool { search.activeItem == result }

  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      VStack(alignment: .leading, spacing: 1) {
        Text(fuzzyHighlight(result.title, query: search.query))
          .font(.system(.body))
          .foregroundStyle(isActive ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
          .lineLimit(1)
          .truncationMode(.tail)
        Text(result.pathDescription)
          .font(.caption2)
          .foregroundStyle(isActive ? AnyShapeStyle(Color.white.opacity(0.85)) : AnyShapeStyle(.tertiary))
          .lineLimit(1)
      }
      Spacer(minLength: 0)
      if !result.command.stringValue.isEmpty {
        ShortcutChip(
          text: result.command.stringValue,
          highlighted: isActive && requireShortcutToInvoke
        )
        .scaleEffect(chipScale)
        .animation(.interpolatingSpring(stiffness: 400, damping: 12), value: chipScale)
        .onChange(of: search.blockedReturnPulse) {
          guard isActive else { return }
          chipScale = 1.2
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            chipScale = 1.0
          }
        }
      }
    }
    .contentShape(Rectangle())
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
    .background(
      RoundedRectangle(cornerRadius: 6, style: .continuous)
        .fill(rowBackground)
    )
    .onHover { hovering = $0 }
  }

  private var rowBackground: Color {
    if isActive { return Color.accentColor }
    if hovering { return Color.primary.opacity(0.08) }
    return Color.clear
  }
}


struct FooterHintView: View {
  @EnvironmentObject var search: SearchSession
  @AppStorage("requireShortcutToInvoke") private var requireShortcutToInvoke = true

  var body: some View {
    let shortcut = search.activeItem?.command.stringValue ?? ""
    let hint: String
    if requireShortcutToInvoke && !shortcut.isEmpty {
      hint = "Press \(shortcut) to invoke"
    } else {
      hint = "↵ Return to invoke"
    }
    return Text(hint)
      .font(.system(.caption, design: .rounded))
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .center)
  }
}
