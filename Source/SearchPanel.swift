//
//  MenuSearchPanel.swift
//  Menuet
//
//

import SwiftUI


class SearchPanel: FloatingActionPanel {

  init(contentRect: NSRect, view: () -> some View) {
    super.init(contentRect: contentRect)

    let hostingView = NSHostingView(rootView: view().ignoresSafeArea())
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    hostingView.sizingOptions = .standardBounds
    contentView = hostingView
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if let item = SearchSession.shared.findMatchingResult({ $0.command.matches(event) }) {
      dismissAndPerform(item.command)
      return true
    }
    return super.performKeyEquivalent(with: event)
  }
}
