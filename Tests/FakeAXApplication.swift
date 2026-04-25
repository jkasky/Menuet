//
//  FakeAXApplication.swift
//  MenuBarProTests
//

import Foundation


class FakeAXApplication: AccessibilityApplication {

  var menuBar: AX.Element?
  var topElement: AX.Element

  init(menuBar: AX.Element? = nil, topElement: AX.Element = FakeAXElement()) {
    self.menuBar = menuBar
    self.topElement = topElement
  }
}
