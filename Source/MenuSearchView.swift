//
//  MenuSearchView.swift
//  MenuBar Pro
//
//  Created by Jesse Kasky on 7/22/23.
//  Copyright © 2023 Codjax. All rights reserved.
//

import SwiftUI

struct MenuSearchView: View {
  @EnvironmentObject var searchManager: SearchManager

  var body: some View {
    ZStack() {
      RoundedRectangle(cornerRadius: 16.0, style: .circular)
        .foregroundColor(Color(nsColor: .controlBackgroundColor))
      VStack() {
        SearchView()
        if (!searchManager.searchResults.isEmpty) {
          Divider()
          ResultsView()
        }
      }
      .padding(.top, 10.0)
      .padding(.bottom, 10.0)
    }
    .background(.clear)
    .containerShape(RoundedRectangle(cornerRadius: 16.0))
    .frame(minWidth: 600, maxWidth:600, minHeight: 40, maxHeight: 500)
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
    } else {
      placeholder
    }
  }
}

struct SearchView: View {
  @EnvironmentObject var searchManager: SearchManager

  var body: some View {
    HStack() {
      AppIcon()
      TextField("Menu Search", text: $searchManager.query)
        .font(.system(size: 24))
        .textFieldStyle(.plain)
    }
    .padding(.leading, 10)
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
        VStack(alignment: .leading) {
          ForEach($searchManager.searchResults.indices, id: \.self) { index in
            ResultView(result: $searchManager.searchResults[index], index: index)
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
        .padding(.leading, 10.0)
        .padding(.trailing, 25.0)
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
  @State var index: Int
  @State var isActive: Bool = false

  var body: some View {
    HStack(alignment: .top) {
      Text(index < 7 ? "\(KeyGlyph.Command.characters)\(index + 1)" : "")
        .frame(minWidth: 32)
      VStack(alignment: .leading) {
        Text(result.title)
        Text(result.pathDescription)
          .font(.system(size: 12))
          .foregroundColor(Color(nsColor: .secondaryLabelColor))
      }
      Spacer()
      Text(result.command.stringValue)
    }
    .frame(maxWidth: .infinity)
    .padding([.top, .bottom], 3)
    .padding(.trailing, 5)
    .background(isActive ? Color.accentColor : Color.clear)
    .onReceive(searchManager.$activeItem) { activeItem in
      if let item = activeItem {
        isActive = result == item
      } else {
        isActive = false
      }
    }
  }
}
