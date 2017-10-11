//
//  MenuItemCommand.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 8/6/17.
//  Copyright © 2017 Codjax. All rights reserved.
//

import XCTest

class MenuItemCommandTest: XCTestCase {

  func testNormalCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 0))
    XCTAssertEqual(c.stringValue, "⌘C")
  }

  func testShiftAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 1))
    XCTAssertEqual(c.stringValue, "⇧⌘C")
  }

  func testOptionAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 2))
    XCTAssertEqual(c.stringValue, "⌥⌘C")
  }

  func testOptionShiftAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 3))
    XCTAssertEqual(c.stringValue, "⌥⇧⌘C")
  }

  func testControlAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 4))
    XCTAssertEqual(c.stringValue, "⌃⌘C")
  }

  func testControlShiftAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 5))
    XCTAssertEqual(c.stringValue, "⌃⇧⌘C")
  }

  func testControlOptionAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 6))
    XCTAssertEqual(c.stringValue, "⌃⌥⌘C")
  }

  func testControlOptionShiftAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 7))
    XCTAssertEqual(c.stringValue, "⌃⌥⇧⌘C")
  }

  func testNoCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 8))
    XCTAssertEqual(c.stringValue, "C")
  }

  func testShiftModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 9))
    XCTAssertEqual(c.stringValue, "⇧C")
  }

  func testOptionModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 10))
    XCTAssertEqual(c.stringValue, "⌥C")
  }

  func testOptionAndShiftModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 11))
    XCTAssertEqual(c.stringValue, "⌥⇧C")
  }

  func testControlModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 12))
    XCTAssertEqual(c.stringValue, "⌃C")
  }

  func testControlAndShiftModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 13))
    XCTAssertEqual(c.stringValue, "⌃⇧C")
  }

  func testControlAndOptionModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 14))
    XCTAssertEqual(c.stringValue, "⌃⌥C")
  }

  func testControlOptionAndShiftModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:AXMenuItemModifiers(rawValue: 15))
    XCTAssertEqual(c.stringValue, "⌃⌥⇧C")
  }
}
