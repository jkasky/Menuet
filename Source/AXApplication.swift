//
//  AXApplication.swift
//  MenuFinder
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

  var title: String { get }

  func childAt(_ index: UInt) -> AX.Element?

  func find(_ role: AX.Role) throws -> AX.Element?

  func findAll(_ role: AX.Role) throws -> [AX.Element]

  func get(_ attribute: AX.Attribute) throws -> AX.Element

  func get(_ attribute: AX.Attribute) throws -> String

  func get(_ attribute: AX.Attribute) throws -> Bool

  func get(_ attribute: AX.Attribute) throws -> Int

  func isA(_: AX.Role) -> Bool

  func perform(action: AX.Action) throws
}


protocol AXMenuVisitor {

  func enterMenu(_: AX.Element)

  func leaveMenu(_: AX.Element)

  func visitMenuItem(_: AX.Element)

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


class AXMenuWalker {

  private let application:AX.Element

  init(application: AX.Element) {
    self.application = application
  }

  func walk(visitor: AXMenuVisitor) throws {
    let menuBar: AX.Element = try application.get(.MenuBar)
    for menuBarItem: AX.Element in try menuBar.findAll(.MenuBarItem) {
      let menu: AX.Element? = try menuBarItem.find(.Menu)
      guard menu != nil else {
        continue
      }
      visitor.enterMenu(menuBarItem)
      walkMenu(menu: menu!, visitor: visitor)
      visitor.leaveMenu(menuBarItem)
    }
  }

  private func walkMenu(menu: AX.Element, visitor: AXMenuVisitor) {
    for item in (try? menu.findAll(.MenuItem)) ?? [] {
      switch item.childCount {
      // Single child element with role of Menu for sub-menus
      case 1:
        if let menu = try? item.find(.Menu) as AX.Element? {
          visitor.enterMenu(item)
          walkMenu(menu: menu, visitor: visitor)
          visitor.leaveMenu(item)
        }
      default:
        visitor.visitMenuItem(item)
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

  init(element: AXUIElement) {
    self.element = element
    self.cachedChildren = Array<AX.Element>()
  }

  private var cachedChildren:[AX.Element]

  var childCount: Int {
    get {
      let value:AnyObject? = try? get(.Children)
      guard value != nil else {
        return 0
      }
      return CFArrayGetCount((value as! CFArray))
    }
  }

  var children: [AX.Element] {
    get {
      if cachedChildren.isEmpty && childCount > 0 {
        guard let value:AnyObject = try? get(.Children) else {
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

  var title: String {
    get {
      guard let value: String = try? get(.Title) else {
        return ""
      }
      return value
    }
  }

  func childAt(_ index: UInt) -> AX.Element? {
    return children[Int(index)]
  }

  func find(_ role: AX.Role) throws -> AX.Element? {
    return children.first {
      return $0.isA(role)
    }
  }

  func findAll(_ role: AX.Role) throws -> [AX.Element] {
    return children.filter {
      return $0.isA(role)
    }
  }

  /**
   * Returns the value of an accessibility attribute.
   */
  private func get(_ attribute: AX.Attribute) throws -> AnyObject {
    let name = attribute.rawValue as NSString
    var value: AnyObject?
    let error = AXUIElementCopyAttributeValue(element, name, &value)
    guard error == .success else {
      throw AX.APIError(code: error)
    }
    guard value != nil else {
      throw AX.Error.attributeNotFound(attribute)
    }
    return value!
  }

  func get(_ attribute: AX.Attribute) throws -> AX.Element {
    let value: AnyObject = try get(attribute)
    let typeId = CFGetTypeID(value)
    guard typeId == AXUIElementGetTypeID() else {
      throw AX.Error.invalidType(CFCopyTypeIDDescription(typeId) as String)
    }
    return AXElement(element: value as! AXUIElement)
  }

  func get(_ attribute: AX.Attribute) throws -> String {
    let value: AnyObject = try get(attribute)
    let typeId = CFGetTypeID(value)
    guard typeId == CFStringGetTypeID() else {
      throw AX.Error.invalidType(CFCopyTypeIDDescription(typeId) as String)
    }
    return value as! CFString as String
  }

  func get(_ attribute: AX.Attribute) throws -> Bool {
    let value: AnyObject = try get(attribute)
    let typeId = CFGetTypeID(value)
    guard typeId == CFBooleanGetTypeID() else {
      throw AX.Error.invalidType(CFCopyTypeIDDescription(typeId) as String)
    }
    return (value as! CFBoolean) == kCFBooleanTrue ? true : false
  }

  /**
   Returns an attribute value as an integer.
   
   If the attribute value is not a whole number then it will be rounded
   towards zero.
  
   - Parameters:
     - attribute: the attribute to get
   
   - Throws:
     - `AX.APIError`
     - `AX.Error.invalidType`
   */
  func get(_ attribute: AX.Attribute) throws -> Int {
    let value: AnyObject = try get(attribute)
    let typeId = CFGetTypeID(value)
    guard typeId == CFNumberGetTypeID() else {
      throw AX.Error.invalidType(CFCopyTypeIDDescription(typeId) as String)
    }
    let number = value as! CFNumber as NSNumber
    return Int(truncating: number)
  }

  func isA(_ role: AX.Role) -> Bool {
    do {
      return try get(.Role) as String == role.rawValue
    } catch {
      return false
    }
  }

  func perform(action: AX.Action) throws {
    let error = AXUIElementPerformAction(element, action.rawValue as NSString)
    guard error == .success else {
      throw AX.APIError(code: error)
    }
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
