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

  var application: AX.Application { owningApplication }
  var childCount: Int { children.count }
  var title: String { stringAttributes[.Title] ?? "" }

  func childAt(_ index: UInt) -> AX.Element? {
    let i = Int(index)
    return i < children.count ? children[i] : nil
  }

  func find(_ role: AX.Role) -> AX.Element? {
    return children.first { $0.isA(role) }
  }

  func findAll(_ role: AX.Role) -> [AX.Element] {
    return children.filter { $0.isA(role) }
  }

  func get(_ attribute: AX.Attribute) throws -> AX.Element {
    guard let v = elementAttributes[attribute] else {
      throw AX.Error.attributeNotFound(attribute)
    }
    return v
  }

  func get(_ attribute: AX.Attribute) throws -> String {
    guard let v = stringAttributes[attribute] else {
      throw AX.Error.attributeNotFound(attribute)
    }
    return v
  }

  func get(_ attribute: AX.Attribute) throws -> Bool {
    guard let v = boolAttributes[attribute] else {
      throw AX.Error.attributeNotFound(attribute)
    }
    return v
  }

  func get(_ attribute: AX.Attribute) throws -> Int {
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
}
