//
//  AXElement.swift
//  Menumate
//
//  Created by Jesse Kasky on 2/8/21.
//  Copyright © 2021 Codjax. All rights reserved.
//


import Foundation


extension AX {
  typealias Element = AccessibilityElement
}


protocol AccessibilityElement {

  /**
   Application owning the element.
   */
  var application: AX.Application { get }

  /**
   Number of children under the element.
   */
  var childCount: Int { get }

  /**
   Title attribute of element.
   */
  var title: String { get }

  /**
   Retrieves child element at given index.

   - parameter index: integer index of child
   - throws:
     - `AX.APIError` if getting the child fails
   - returns: child element
   */
  func childAt(_ index: UInt) -> AX.Element?

  /**
   Find first child element that matches given role.

   - parameter role: role to evaluate children against
   - throws:
     - `AX.APIError` if search fails
   - returns: first element matching role
   */
  func find(_ role: AX.Role) throws -> AX.Element?

  /**
   Find all child elements that match given role.

   - parameter role: role to evaluate children against
   - throws:
     - `AX.APIError` if search fails
   - returns: array of matching child elements
   */
  func findAll(_ role: AX.Role) throws -> [AX.Element]

  /**
   Returns an attribute value as an element.

   - parameter attribute: the attribute to get

   - throws:
     - `AX.APIError` if getting the attribute fails
     - `AX.Error.invalidType` if attribute is not an element

   - returns: element attribute value
   */
  func get(_ attribute: AX.Attribute) throws -> AX.Element

  /**
   Returns an attribute value as a string.

   - parameter attribute: the attribute to get

   - throws:
     - `AX.APIError` if getting the attribute fails
     - `AX.Error.invalidType` if attribute is not a string

   - returns: string attribute value
   */
  func get(_ attribute: AX.Attribute) throws -> String

  /**
   Returns an attribute value as a boolean.

   - parameter attribute: the attribute to get

   - throws:
     - `AX.APIError` if getting the attribute fails
     - `AX.Error.invalidType` if attribute is not a boolean

   - returns: boolean attribute value
   */
  func get(_ attribute: AX.Attribute) throws -> Bool

  /**
   Returns an attribute value as an integer.

   - parameter attribute: the attribute to get

   - throws:
     - `AX.APIError` if getting the attribute fails
     - `AX.Error.invalidType` if attribute is not an integer

   - returns: integer attribute value

   If the attribute value is not a whole number then it will be rounded
   towards zero.
   */
  func get(_ attribute: AX.Attribute) throws -> Int

  /**
   Returns true if element is the given role.

   - parameter role: the role to check

   - throws:
     - `AX.APIError` if check fails
   */
  func isA(_ role: AX.Role) -> Bool

  /**
   Perform a given action.

   - parameter action: the action to perform
   - throws:
     - `AX.APIError` if perform fails
   */
  func perform(action: AX.Action) throws

  /**
   Set messaging timeout of the element

   - parameter seconds: timeout value in seconds
   - throws:
     - `AX.APIError` if setting the messaging fails
   */
  func setMessagingTimeout(_ seconds: Float) throws
}


class AXElement: AX.Element {

  private let element: AXUIElement

  init(element: AXUIElement) {
    self.element = element
    self.cachedChildren = Array<AX.Element>()
  }

  private var cachedChildren:[AX.Element]

  var application: AX.Application {
    get {
      var pid: pid_t = -1
      AXUIElementGetPid(element, &pid)
      return AXApplication(pid: pid)
    }
  }

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
    let status = AXUIElementPerformAction(element, action.rawValue as NSString)
    guard status == .success else {
      let error = AX.APIError(code: status)
      #if DEBUG
      NSLog("Failed to perform '\(action)' on \(self): \(error.description)")
      #endif
      throw error
    }
  }

  func setMessagingTimeout(_ seconds: Float) throws {
    let status = AXUIElementSetMessagingTimeout(element, seconds)
    guard status == .success else {
      let error = AX.APIError(code: status)
      throw error
    }
  }
}
