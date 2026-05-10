//
//  AXApplication.swift
//  Menuet
//
//

import ApplicationServices
import Foundation
import OSLog


private let logger = Logger(subsystem: "app.menuet", category: "ax")


extension AX {
  typealias Application = AccessibilityApplication
}


protocol AccessibilityApplication {

  /**
   Menubar of the application.
   */
  var menuBar: AX.Element? { get }

  /**
   Top element of the application.
   */
  var topElement: AX.Element { get }
}


class AXApplication: AccessibilityApplication {
  let topElement: AX.Element

  var menuBar: AX.Element? {
    get {
      do {
        let menuBar: AX.Element = try topElement.get(.MenuBar)
        return menuBar
      } catch {
        logger.error("failed to get menubar: \(error.localizedDescription, privacy: .public)")
      }
      return nil
    }
  }

  init(pid: pid_t) {
    topElement = AXElement(element: AXUIElementCreateApplication(pid))
  }
}
