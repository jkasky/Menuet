//
//  AXVisitor.swift
//  Menumate
//
//  Created by Jesse Kasky on 2/8/21.
//  Copyright © 2021 Codjax. All rights reserved.
//

import Foundation


protocol AXMenuVisitor {

  func enterMenu(_: AX.Element)

  func leaveMenu(_: AX.Element)

  func visitMenuItem(_: AX.Element)

}


class AXMenuWalker {

  private let application:AX.Element

  init(application: AX.Element) {
    self.application = application
  }

  func walk(visitor: AXMenuVisitor) throws {
    let menuBar: AX.Element = try application.get(.MenuBar)
    for menuBarItem in menuBar.findAll(.MenuBarItem) {
      guard let menu = menuBarItem.find(.Menu) else { continue }
      visitor.enterMenu(menuBarItem)
      walkMenu(menu: menu, visitor: visitor)
      visitor.leaveMenu(menuBarItem)
    }
  }

  private func walkMenu(menu: AX.Element, visitor: AXMenuVisitor) {
    for item in menu.findAll(.MenuItem) {
      switch item.childCount {
      // Single child element with role of Menu for sub-menus
      case 1:
        if let submenu = item.find(.Menu) {
          visitor.enterMenu(item)
          walkMenu(menu: submenu, visitor: visitor)
          visitor.leaveMenu(item)
        }
      default:
        visitor.visitMenuItem(item)
      }
    }
  }
}


class AXMenuItemPath {

  let application: AX.Application
  let path: [UInt]

  init(application: AX.Application, path: [UInt]) {
    self.application = application
    self.path = path
  }

  func get() -> AX.Element? {
    var nextElement: AX.Element? = try? application.topElement.get(.MenuBar)
    for i in path {
      guard let currentElement = nextElement else {
        break
      }
      if currentElement.isA(.MenuBar) {
        nextElement = currentElement.childAt(i)
        continue
      }
      if currentElement.isA(.MenuBarItem) {
        nextElement = currentElement.childAt(0)?.childAt(i)
        continue
      }
      if currentElement.isA(.MenuItem) {
        nextElement = currentElement.childAt(0)?.childAt(i)
        continue
      }
    }
    return nextElement
  }
}


class AXMenuLogger: AXMenuVisitor {

  var indent:Int = 0

  func enterMenu(_ menu: AX.Element) {
    if let title: String = try? menu.get(.Title) {
      NSLog(String(repeating: " ", count: indent) + "\(title)")
      indent += 2
    }
  }

  func leaveMenu(_ menu: AX.Element) {
    indent -= 2
  }

  func visitMenuItem(_ item: AX.Element) {
    if let title: String = try? item.get(.Title) {
      let enabled: Bool = (try? item.get(.Enabled)) ?? false
      let commandChar: String = (try? item.get(.MenuItemCmdChar)) ?? ""
      let commandModifiers: Int = (try? item.get(.MenuItemCmdModifiers)) ?? 0
      let modifiers = Modifiers(rawValue: commandModifiers)
      let commandItem = MenuItemCommand(
        character:commandChar,
        modifiers:modifiers,
        delegate:AXMenuItemDelegate(item, path: []))
      NSLog(String(repeating: " ", count: indent) +
        "\(title), Command:\(commandItem.stringValue), Enabled:\(enabled)")
    }
  }
}
