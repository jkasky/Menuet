//
//  FakeAXElement.swift
//  MenuetTests
//

import Foundation


class FakeAXElement: AccessibilityElement {

  var role: AX.Role = .Unknown
  var children: [AX.Element] = []
  lazy var owningApplication: AX.Application = FakeAXApplication()

  var elementAttributes: [AX.Attribute: AX.Element] = [:]
  var stringAttributes: [AX.Attribute: String] = [:]
  var boolAttributes: [AX.Attribute: Bool] = [:]
  var intAttributes: [AX.Attribute: Int] = [:]

  // Diagnostic enumeration backing stores (used by the CLI dump path).
  var actionNamesList: [String] = []
  var attributeNamesList: [String] = []
  var attributeDescriptions: [String: String] = [:]
  var settableAttributeNames: Set<String> = []
  var parameterizedAttributeNamesList: [String] = []
  var actionDescriptionMap: [String: String] = [:]

  /// Optional virtual clock advanced on each attribute access. Tests
  /// share one `VirtualClock` between the walker (via init) and its fake
  /// elements so the walker's deadline check sees time pass as fakes
  /// "respond." When `clock` is nil or `responseDelay` is 0, attribute
  /// access is free — preserving existing test behavior.
  var clock: VirtualClock?
  var responseDelay: TimeInterval = 0

  private func tick() {
    if let clock = clock, responseDelay > 0 {
      clock.advance(by: responseDelay)
    }
  }

  var application: AX.Application { owningApplication }
  var childCount: Int { tick(); return children.count }
  var title: String { tick(); return stringAttributes[.Title] ?? "" }

  func childAt(_ index: UInt) -> AX.Element? {
    tick()
    let i = Int(index)
    return i < children.count ? children[i] : nil
  }

  func find(_ role: AX.Role) -> AX.Element? {
    tick()
    return children.first { $0.isA(role) }
  }

  func findAll(_ role: AX.Role) -> [AX.Element] {
    tick()
    return children.filter { $0.isA(role) }
  }

  func get(_ attribute: AX.Attribute) throws -> AX.Element {
    tick()
    guard let v = elementAttributes[attribute] else {
      throw AX.Error.attributeNotFound(attribute)
    }
    return v
  }

  func get(_ attribute: AX.Attribute) throws -> String {
    tick()
    guard let v = stringAttributes[attribute] else {
      throw AX.Error.attributeNotFound(attribute)
    }
    return v
  }

  func get(_ attribute: AX.Attribute) throws -> Bool {
    tick()
    guard let v = boolAttributes[attribute] else {
      throw AX.Error.attributeNotFound(attribute)
    }
    return v
  }

  func get(_ attribute: AX.Attribute) throws -> Int {
    tick()
    guard let v = intAttributes[attribute] else {
      throw AX.Error.attributeNotFound(attribute)
    }
    return v
  }

  func isA(_ role: AX.Role) -> Bool {
    return self.role == role
  }

  func perform(action: AX.Action) throws {}

  func setMessagingTimeout(_ seconds: Float) throws {}

  func attributeNames() -> [String] { attributeNamesList }

  func actionNames() -> [String] { actionNamesList }

  func attributeValueDescription(_ name: String) -> String? {
    attributeDescriptions[name]
  }

  func isAttributeSettable(_ name: String) -> Bool {
    settableAttributeNames.contains(name)
  }

  func parameterizedAttributeNames() -> [String] {
    parameterizedAttributeNamesList
  }

  func actionDescription(_ name: String) -> String? {
    actionDescriptionMap[name]
  }
}
