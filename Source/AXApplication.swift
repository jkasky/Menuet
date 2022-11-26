//
//  AXApplication.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 7/11/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import ApplicationServices
import Foundation


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
  let top: AX.Element

  var topElement: AX.Element {
    get {
      return top
    }
  }

  var menuBar: AX.Element? {
    get {
      do {
        let menuBar: AX.Element = try top.get(.MenuBar)
        return menuBar
      } catch {
        #if DEBUG
        NSLog("failed to get menubar for \(top)")
        #endif
      }
      return nil
    }
  }

  init(pid: pid_t) {
    top = AXElement(element: AXUIElementCreateApplication(pid))
  }
}
