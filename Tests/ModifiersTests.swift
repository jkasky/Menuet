//
//  ModifiersTests.swift
//  MenuetTests
//

import AppKit
import XCTest


// AX encodes AXMenuItemCmdModifiers with bit 8 *set* when Command is
// absent. `Modifiers(axRawValue:)` flips that at the boundary so the
// rest of the code can read modifiers in plain positive terms — these
// tests pin the translation table.
class ModifiersAXBoundaryTests: XCTestCase {

  func testRawZeroIsCommandAlone() {
    XCTAssertEqual(Modifiers(axRawValue: 0), [.command])
  }

  func testNoCommandBitClearsCommand() {
    XCTAssertEqual(Modifiers(axRawValue: 8), [])
  }

  func testShiftWithCommand() {
    XCTAssertEqual(Modifiers(axRawValue: 1), [.shift, .command])
  }

  func testShiftWithoutCommand() {
    XCTAssertEqual(Modifiers(axRawValue: 1 | 8), [.shift])
  }

  func testControlOptionShiftWithoutCommand() {
    XCTAssertEqual(
      Modifiers(axRawValue: 1 | 2 | 4 | 8),
      [.shift, .option, .control])
  }

  func testControlOptionShiftWithCommand() {
    XCTAssertEqual(
      Modifiers(axRawValue: 1 | 2 | 4),
      [.shift, .option, .control, .command])
  }

  func testFunctionBitSurvives() {
    XCTAssertEqual(Modifiers(axRawValue: 16), [.function, .command])
    XCTAssertEqual(Modifiers(axRawValue: 16 | 8), [.function])
  }
}


class ModifiersEventFlagsTests: XCTestCase {

  func testEmptyFlags() {
    XCTAssertEqual(Modifiers(eventFlags: []), [])
  }

  func testCommandOnly() {
    XCTAssertEqual(Modifiers(eventFlags: [.command]), [.command])
  }

  func testAllFiveBits() {
    XCTAssertEqual(
      Modifiers(eventFlags: [.shift, .control, .option, .command, .function]),
      [.shift, .option, .control, .command, .function])
  }

  // The == overload against NSEvent.ModifierFlags is the canonical
  // shortcut-vs-event check used by `MenuItemCommand.matches`.
  func testEqualityAgainstEventFlags() {
    XCTAssertTrue(Modifiers([.command]) == NSEvent.ModifierFlags([.command]))
    XCTAssertTrue(Modifiers([.shift, .command]) == NSEvent.ModifierFlags([.shift, .command]))
    XCTAssertFalse(Modifiers([.command]) == NSEvent.ModifierFlags([.shift, .command]))
    XCTAssertFalse(Modifiers([]) == NSEvent.ModifierFlags([.command]))
  }
}
