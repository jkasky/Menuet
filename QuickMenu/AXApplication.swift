//
//  AXApplication.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 7/11/15.
//  Copyright (c) 2015 Codjax. All rights reserved.
//

import Foundation


extension AX {
  typealias Application = AXApplication
  typealias AttributeValue = AXAttributeValue
  typealias Element = AXElementProtocol
}


protocol AXElementProtocol {

  var childCount: Int { get }

  func find(_ role: AX.Role) -> AX.Element?

  func findAll(_ role: AX.Role) -> [AX.Element]

  func get(_ attribute: AX.Attribute) -> AX.Element?

  func get(_ attribute: AX.Attribute) -> String?

  func perform(action: AX.Action)
}


protocol AXMenuVisitor {

  func visitMenu()

  func visitMenuItem()

}


class AXMenuWalker {

  private let application:AX.Element

  init(application: AX.Element) {
    self.application = application
  }

  func walk(visitor: AXMenuVisitor) {
    let menuBar:AX.Element = application.get(.MenuBar)!
    for menuBarItem in menuBar.findAll(.MenuBarItem) {
      visitor.visitMenu()
      let menu:AX.Element? = menuBarItem.find(.Menu)
      guard menu != nil else {
        continue
      }
      walkMenu(menu: menu!, visitor: visitor)
    }
  }

  private func walkMenu(menu: AX.Element, visitor: AXMenuVisitor) {
    for item in menu.findAll(.MenuItem) {
      switch item.childCount {
      case 0:
        visitor.visitMenuItem()
      case 1:
        let menu = item.find(.Menu)
        guard menu != nil else {
          continue
        }
        visitor.visitMenu()
        walkMenu(menu: menu!, visitor: visitor)
      default:
        continue
      }
    }
  }
}


struct AXAttributeValue {

  private let element: AXUIElement
  let name: String

  init(element: AXUIElement, name: String) {
    self.element = element
    self.name = name
  }

  var value: AnyObject? {
    let name = self.name as CFString
    var error: AXError?
    var value: AnyObject?
    error = AXUIElementCopyAttributeValue(element, name, &value)
    guard error == .success else {
      return nil
    }
    return value
  }
}


class AXElement: AXElementProtocol {

  private let element: AXUIElement

//  private func _copyNames(
//    copyFunc: (AXUIElement, UnsafeMutablePointer<CFArray?>) -> AXError,
//    element: AXUIElement
//    ) -> [NSString] {
//    var error: AXError?
//    var names: CFArray?
//    error = copyFunc(element, &names)
//    guard error == .success && names != nil else {
//      return []
//    }
//    if let names = names as? [NSString] {
//      return names
//    }
//    return []
//  }
//
//  var actionNames: [AX.ActionName] {
//    get {
//      let names = _copyNames(
//        copyFunc: AXUIElementCopyActionNames, element: element)
//      return names.flatMap {
//        (n: NSString) -> AX.ActionName? in
//        let value = n as String
//        if let a = AX.ActionName(rawValue: value) {
//          return a
//        } else {
//          NSLog("Unknown action \(value)")
//          return nil
//        }
//      }
//    }
//  }
//
//  var attributeNames: [AX.AttributeName] {
//    get {
//      let names = _copyNames(
//        copyFunc: AXUIElementCopyAttributeNames, element: element)
//      return names.flatMap {
//        (n: NSString) -> AX.AttributeName? in
//        let value = n as String
//        if let a = AX.AttributeName(rawValue: value) {
//          return a
//        } else {
//          NSLog("Unknown attribute \(value)")
//          return nil
//        }
//      }
//    }
//  }
//
//  var attributes: [AXAttribute] {
//    get {
//      var values = Array<AXAttribute>()
//      for name in attributeNames {
//        values.append(AXAttribute(element: element, name: name.rawValue))
//      }
//      return values
//    }
//  }

  init(element: AXUIElement) {
    self.element = element
  }

  deinit {

  }

  var childCount: Int {
    get {
      let value:AnyObject? = get(.Children)
      guard value != nil else {
        return 0
      }
      return CFArrayGetCount(value as! CFArray)
    }
  }

  func find(_ role: AX.Role) -> AX.Element? {
    return nil
  }

  func findAll(_ role: AX.Role) -> [AX.Element] {
    return []
  }

  private func get(_ attribute: AX.Attribute) -> AnyObject? {
    let name = attribute.rawValue as NSString
    var error: AXError?
    var value: AnyObject?
    error = AXUIElementCopyAttributeValue(element, name, &value)
    guard error == .success else {
      return nil
    }
    return value
  }

  func get(_ attribute: AX.Attribute) -> AX.Element? {
    let value: AnyObject? = get(attribute)
    guard value != nil else {
      return nil
    }
    return AXElement(element: value as! AXUIElement)
  }

  func get(_ attribute: AX.Attribute) -> String? {
    let value: AnyObject? = get(attribute)
    return value as! CFString as String
  }

  func perform(action: AX.Action) {

  }
}


class AXApplication {
  let pid: pid_t
  let topElement: AX.Element

  init(pid: pid_t) {
    self.pid = pid
    topElement = AXElement(element: AXUIElementCreateApplication(self.pid))
  }
}
