//
//  AXElement.swift
//  Menuet
//
//


import ApplicationServices
import Foundation
import OSLog


private let logger = Logger(subsystem: "app.menuet", category: "ax")


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
   - returns: first element matching role
   */
  func find(_ role: AX.Role) -> AX.Element?

  /**
   Find all child elements that match given role.

   - parameter role: role to evaluate children against
   - returns: array of matching child elements
   */
  func findAll(_ role: AX.Role) -> [AX.Element]

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

  /**
   Names of every attribute this element supports
   (`AXUIElementCopyAttributeNames`). Diagnostic enumeration — unlike the
   typed `get(_:)` accessors, this surfaces *all* attributes an element
   exposes, including ones not modeled by `AX.Attribute`. Returns an empty
   array on failure.
   */
  func attributeNames() -> [String]

  /**
   Names of every action this element supports
   (`AXUIElementCopyActionNames`). The wrapper otherwise only ever
   *performs* actions; this lets callers ask whether e.g. `AXPress` is
   advertised at all. Returns an empty array on failure.
   */
  func actionNames() -> [String]

  /**
   Best-effort string description of an attribute's current value, looked up
   by raw attribute name. Handles the CF types AX returns (element, string,
   bool, number, array, `AXValue` geometry). Returns nil when the attribute
   is absent or unreadable.

   - parameter name: raw attribute name (e.g. `"AXSubrole"`)
   */
  func attributeValueDescription(_ name: String) -> String?

  /**
   Whether an attribute is writable (`AXUIElementIsAttributeSettable`). This is
   metadata `attributeNames()` can't surface: two elements may both *list*
   `AXSelected` while only one allows *setting* it — e.g. a real, selectable
   menu item vs a non-interactive section header. Returns false on failure.
   */
  func isAttributeSettable(_ name: String) -> Bool

  /**
   Names of parameterized attributes (`AXUIElementCopyParameterizedAttributeNames`)
   — a separate namespace from `attributeNames()` for query-style attributes
   that take an argument (e.g. `AXStringForRange`). Returns an empty array on
   failure.
   */
  func parameterizedAttributeNames() -> [String]

  /**
   Human-readable description of an action (`AXUIElementCopyActionDescription`),
   by raw action name. Returns nil when absent.
   */
  func actionDescription(_ name: String) -> String?
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
    return children.count
  }

  var children: [AX.Element] {
    get {
      if cachedChildren.isEmpty {
        guard let value: AnyObject = try? get(.Children) else {
          return []
        }
        // AXChildren comes from another process; a buggy AX implementation
        // (Electron, Java, Catalyst) can hand back a wrong-typed value. Verify
        // the CFTypeID before casting — a force-cast here would crash Menuet,
        // not the target — mirroring the typed get(_:) accessors below.
        guard CFGetTypeID(value) == CFArrayGetTypeID() else {
          logger.error("AXChildren was not an array: \(CFCopyTypeIDDescription(CFGetTypeID(value)) as String, privacy: .public)")
          return []
        }
        let untyped = ((value as! CFArray) as NSArray) as [AnyObject]
        for child in untyped where CFGetTypeID(child) == AXUIElementGetTypeID() {
          cachedChildren.append(AXElement(element: child as! AXUIElement))
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
    let i = Int(index)
    guard i < children.count else { return nil }
    return children[i]
  }

  func find(_ role: AX.Role) -> AX.Element? {
    return children.first { $0.isA(role) }
  }

  func findAll(_ role: AX.Role) -> [AX.Element] {
    return children.filter { $0.isA(role) }
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
      logger.error("failed to perform '\(action.rawValue, privacy: .public)': \(error.localizedDescription, privacy: .public)")
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

  func attributeNames() -> [String] {
    var names: CFArray?
    guard AXUIElementCopyAttributeNames(element, &names) == .success,
          let names = names as? [String] else {
      return []
    }
    return names
  }

  func actionNames() -> [String] {
    var names: CFArray?
    guard AXUIElementCopyActionNames(element, &names) == .success,
          let names = names as? [String] else {
      return []
    }
    return names
  }

  func attributeValueDescription(_ name: String) -> String? {
    var value: AnyObject?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success,
          let value = value else {
      return nil
    }
    return AXElement.describe(value)
  }

  func isAttributeSettable(_ name: String) -> Bool {
    var settable = DarwinBoolean(false)
    guard AXUIElementIsAttributeSettable(element, name as CFString, &settable) == .success else {
      return false
    }
    return settable.boolValue
  }

  func parameterizedAttributeNames() -> [String] {
    var names: CFArray?
    guard AXUIElementCopyParameterizedAttributeNames(element, &names) == .success,
          let names = names as? [String] else {
      return []
    }
    return names
  }

  func actionDescription(_ name: String) -> String? {
    var description: CFString?
    guard AXUIElementCopyActionDescription(element, name as CFString, &description) == .success else {
      return nil
    }
    return description as String?
  }

  /// Best-effort stringify of an arbitrary AX attribute value. Kept narrow
  /// on purpose: nested elements/arrays are summarized rather than expanded
  /// so a diagnostic dump of a deep tree can't explode.
  private static func describe(_ value: AnyObject) -> String {
    let typeId = CFGetTypeID(value)
    switch typeId {
    case AXUIElementGetTypeID():
      let element = AXElement(element: value as! AXUIElement)
      let role = (try? element.get(.Role) as String) ?? "?"
      let title = element.title
      return title.isEmpty ? role : "\(role) '\(title)'"
    case CFStringGetTypeID():
      return value as! CFString as String
    case CFBooleanGetTypeID():
      return (value as! CFBoolean) == kCFBooleanTrue ? "true" : "false"
    case CFNumberGetTypeID():
      return "\(value as! CFNumber as NSNumber)"
    case CFArrayGetTypeID():
      let array = (value as! CFArray) as NSArray
      return "[\(array.count) item\(array.count == 1 ? "" : "s")]"
    case AXValueGetTypeID():
      return describeAXValue(value as! AXValue)
    default:
      return CFCopyDescription(value) as String
    }
  }

  private static func describeAXValue(_ value: AXValue) -> String {
    switch AXValueGetType(value) {
    case .cgPoint:
      var p = CGPoint.zero
      AXValueGetValue(value, .cgPoint, &p)
      return "(x: \(p.x), y: \(p.y))"
    case .cgSize:
      var s = CGSize.zero
      AXValueGetValue(value, .cgSize, &s)
      return "(w: \(s.width), h: \(s.height))"
    case .cgRect:
      var r = CGRect.zero
      AXValueGetValue(value, .cgRect, &r)
      return "(x: \(r.origin.x), y: \(r.origin.y), w: \(r.size.width), h: \(r.size.height))"
    case .cfRange:
      var range = CFRange()
      AXValueGetValue(value, .cfRange, &range)
      return "{location: \(range.location), length: \(range.length)}"
    default:
      return CFCopyDescription(value) as String
    }
  }
}
