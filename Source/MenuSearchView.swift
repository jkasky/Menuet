//
//  MenuSearchView.swift
//  Menuet
//
//

import SwiftUI

struct MenuSearchView: View {
  @EnvironmentObject var searchManager: SearchManager

  var body: some View {
    PanelBackground {
      VStack(alignment: .leading, spacing: 0) {
        SearchView()
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        if !searchManager.searchResults.isEmpty {
          Divider().opacity(0.4)
          ResultsView()
        }
      }
    }
    .frame(minWidth: 600, maxWidth: 600, minHeight: 40, maxHeight: 500)
    .fixedSize()
  }
}

struct MenuSearchView_Previews: PreviewProvider {
    static var previews: some View {
      let searchManager = SearchManager()
      searchManager.query = "About"
      searchManager.activate()
      return MenuSearchView().environmentObject(searchManager)
    }
}

struct AppIcon: View {
  @EnvironmentObject var searchManager: SearchManager
  private var placeholder = Image(systemName: "app")

  var body: some View {
    if let icon = searchManager.currentApp?.icon {
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

struct SearchView: View {
  @EnvironmentObject var searchManager: SearchManager
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack(spacing: 10) {
      AppIcon()
      TextField("Menu Search", text: $searchManager.query)
        .font(.system(.title2, design: .rounded))
        .textFieldStyle(.plain)
        .focused($isFocused)
      if !searchManager.query.isEmpty {
        Text("\(searchManager.searchResults.count) \(searchManager.searchResults.count == 1 ? "match" : "matches")")
          .font(.system(.subheadline, design: .rounded))
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }
    }
    .onChange(of: searchManager.focusTrigger) {
      isFocused = true
    }
    .onReceive(
      searchManager.$query.debounce(for: .seconds(0.4), scheduler: DispatchQueue.main)
    ) { q in
      searchManager.search(q)
    }
  }
}


struct ResultsView: View {
  @EnvironmentObject var searchManager: SearchManager

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 2) {
          ForEach($searchManager.searchResults.indices, id: \.self) { index in
            ResultView(result: $searchManager.searchResults[index])
              .frame(maxWidth: .infinity, alignment: .leading)
              .id(searchManager.searchResults[index].id)
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
      .onReceive(searchManager.$activeItem) { activeItem in
        if let item = activeItem {
          proxy.scrollTo(item.id)
        }
      }
    }
  }
}

struct ResultView: View {
  @EnvironmentObject var searchManager: SearchManager
  @Binding var result: MenuItem
  @State var isActive: Bool = false
  @State private var hovering: Bool = false

  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      VStack(alignment: .leading, spacing: 1) {
        Text(fuzzyHighlight(result.title, query: searchManager.query))
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
        ShortcutChip(text: result.command.stringValue)
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
    .onReceive(searchManager.$activeItem) { activeItem in
      if let item = activeItem {
        isActive = result == item
      } else {
        isActive = false
      }
    }
  }

  private var rowBackground: Color {
    if isActive { return Color.accentColor }
    if hovering { return Color.primary.opacity(0.08) }
    return Color.clear
  }
}
