//
//  MenuSearchPanel.swift
//  Menuet
//
//

import SwiftUI


class SearchPanel: FloatingActionPanel {

  private let search: SearchSession

  init(contentRect: NSRect, menus: IndexProvider, search: SearchSession, view: () -> some View) {
    self.search = search
    super.init(contentRect: contentRect, menus: menus)

    let hostingView = NSHostingView(rootView: view().ignoresSafeArea())
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    hostingView.sizingOptions = .standardBounds
    contentView = hostingView
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if let item = search.findMatchingResult({ $0.command.matches(event) }) {
      dismissAndPerform(item.command)
      return true
    }
    return super.performKeyEquivalent(with: event)
  }
}
