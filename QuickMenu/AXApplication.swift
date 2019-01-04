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

  func get(_ attribute: AX.Attribute) -> Bool?

  func get(_ attribute: AX.Attribute) -> Int?

  func isA(_: AX.Role) -> Bool

  func perform(action: AX.Action)
}


protocol AXMenuVisitor {

  func enterMenu(_: AX.Element)

  func leaveMenu(_: AX.Element)

  func visitMenuItem(_: AX.Element)

}


class AXMenuLogger: AXMenuVisitor {

  var indent:Int = 0

  func enterMenu(_ menu: AX.Element) {
    if let title:String = menu.get(.Title) {
      NSLog(String(repeating: " ", count: indent) + "\(title)")
      indent += 2
    }
  }

  func leaveMenu(_ menu: AX.Element) {
    indent -= 2
  }

  func visitMenuItem(_ item: AX.Element) {
    if let title:String = item.get(.Title) {
      let enabled:Bool = item.get(.Enabled) ?? false
      let menuItemCmdChar = item.get(.MenuItemCmdChar) ?? ""
      let menuItemCmdModifiers = item.get(.MenuItemCmdModifiers) ?? 0
      let modifiers = Modifiers(rawValue: menuItemCmdModifiers)
      let commandItem = MenuItemCommand(
        character:menuItemCmdChar,
        modifiers:modifiers)
      NSLog(String(repeating: " ", count: indent) +
        "\(title), Command:\(commandItem.stringValue), Enabled:\(enabled)")
    }
  }
}


class AXMenuWalker {

  private let application:AX.Element

  init(application: AX.Element) {
    self.application = application
  }

  func walk(visitor: AXMenuVisitor) {
    let menuBar:AX.Element = application.get(.MenuBar)!
    for menuBarItem in menuBar.findAll(.MenuBarItem) {
      let menu:AX.Element? = menuBarItem.find(.Menu)
      guard menu != nil else {
        continue
      }
      visitor.enterMenu(menuBarItem)
      walkMenu(menu: menu!, visitor: visitor)
      visitor.leaveMenu(menuBarItem)
    }
  }

  private func walkMenu(menu: AX.Element, visitor: AXMenuVisitor) {
    for item in menu.findAll(.MenuItem) {
      switch item.childCount {
      case 0:
        visitor.visitMenuItem(item)
      case 1:
        let menu = item.find(.Menu)
        guard menu != nil else {
          continue
        }
        visitor.enterMenu(item)
        walkMenu(menu: menu!, visitor: visitor)
        visitor.leaveMenu(item)
      default:
        NSLog("SKIP")
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
    self.cachedChildren = Array<AX.Element>()
  }

  deinit {

  }

  private var cachedChildren:[AX.Element]

  var childCount: Int {
    get {
      let value:AnyObject? = get(.Children)
      guard value != nil else {
        return 0
      }
      return CFArrayGetCount((value as! CFArray))
    }
  }

  var children: [AX.Element] {
    get {
      if cachedChildren.isEmpty && childCount > 0 {
        guard let value:AnyObject = get(.Children) else {
          return []
        }
        let untyped = ((value as! CFArray) as NSArray) as [AnyObject]
        untyped.forEach {
          cachedChildren.append(AXElement(element: $0 as! AXUIElement))
        }
      }
      return cachedChildren
    }
  }

  func find(_ role: AX.Role) -> AX.Element? {
    return children.first {
      return $0.isA(role)
    }
  }

  func findAll(_ role: AX.Role) -> [AX.Element] {
    return children.filter {
      return $0.isA(role)
    }
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
    if let value: AnyObject = get(attribute) {
      return value as! CFString as String
    }
    return nil
  }

  func get(_ attribute: AX.Attribute) -> Bool? {
    if let value: AnyObject = get(attribute) {
      return (value as! CFBoolean as! Bool)
    }
    return nil
  }

  func get(_ attribute: AX.Attribute) -> Int? {
    if let value: AnyObject = get(attribute) {
      return (value as! CFNumber as! Int)
    }
    return nil
  }

  func isA(_ role: AX.Role) -> Bool {
    guard let myRole:String = get(.Role) else {
      return false
    }
    if myRole == role.rawValue {
      return true
    }
    return false
  }

  func perform(action: AX.Action) {
    AXUIElementPerformAction(element, action.rawValue as NSString)
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
