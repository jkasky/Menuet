//
//  MenuItemCommand.swift
//  MenuetTests
//
//

import XCTest

class MenuItemCommandTest: XCTestCase {

  func testNormalCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 0))
    XCTAssertEqual(c.stringValue, "⌘C")
  }

  func testShiftAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 1))
    XCTAssertEqual(c.stringValue, "⇧⌘C")
  }

  func testOptionAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 2))
    XCTAssertEqual(c.stringValue, "⌥⌘C")
  }

  func testOptionShiftAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 3))
    XCTAssertEqual(c.stringValue, "⌥⇧⌘C")
  }

  func testControlAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 4))
    XCTAssertEqual(c.stringValue, "⌃⌘C")
  }

  func testControlShiftAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 5))
    XCTAssertEqual(c.stringValue, "⌃⇧⌘C")
  }

  func testControlOptionAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 6))
    XCTAssertEqual(c.stringValue, "⌃⌥⌘C")
  }

  func testControlOptionShiftAndCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 7))
    XCTAssertEqual(c.stringValue, "⌃⌥⇧⌘C")
  }

  func testNoCommandModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 8))
    XCTAssertEqual(c.stringValue, "C")
  }

  func testShiftModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 9))
    XCTAssertEqual(c.stringValue, "⇧C")
  }

  func testOptionModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 10))
    XCTAssertEqual(c.stringValue, "⌥C")
  }

  func testOptionAndShiftModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 11))
    XCTAssertEqual(c.stringValue, "⌥⇧C")
  }

  func testControlModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 12))
    XCTAssertEqual(c.stringValue, "⌃C")
  }

  func testControlAndShiftModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 13))
    XCTAssertEqual(c.stringValue, "⌃⇧C")
  }

  func testControlAndOptionModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 14))
    XCTAssertEqual(c.stringValue, "⌃⌥C")
  }

  func testControlOptionAndShiftModifier() {
    let c = MenuItemCommand(
      character: "C", modifiers:Modifiers(rawValue: 15))
    XCTAssertEqual(c.stringValue, "⌃⌥⇧C")
  }
}


class MenuItemCommandMatchesTests: XCTestCase {

  private func makeEvent(
    characters: String,
    charactersIgnoringModifiers: String? = nil,
    flags: NSEvent.ModifierFlags
  ) -> NSEvent {
    return NSEvent.keyEvent(
      with: .keyDown,
      location: .zero,
      modifierFlags: flags,
      timestamp: 0,
      windowNumber: 0,
      context: nil,
      characters: characters,
      charactersIgnoringModifiers: charactersIgnoringModifiers ?? characters,
      isARepeat: false,
      keyCode: 0
    )!
  }

  func testMatchesCommandShortcut() {
    let cmd = MenuItemCommand(character: "C", modifiers: Modifiers(rawValue: 0))
    let event = makeEvent(characters: "c", flags: [.command])
    XCTAssertTrue(cmd.matches(event))
  }

  func testIsCaseInsensitive() {
    let cmd = MenuItemCommand(character: "C", modifiers: Modifiers(rawValue: 0))
    let lower = makeEvent(characters: "c", flags: [.command])
    let upper = makeEvent(characters: "C", flags: [.command])
    XCTAssertTrue(cmd.matches(lower))
    XCTAssertTrue(cmd.matches(upper))
  }

  // Regression: SearchPanel previously had `if characters != ""` which
  // overwrote the modifier-stripped form whenever it was non-empty —
  // the opposite of intent. ⌥E on US layout produces characters="´",
  // charactersIgnoringModifiers="e"; the matcher should use "E".
  func testPrefersCharactersIgnoringModifiers() {
    let cmd = MenuItemCommand(character: "E", modifiers: Modifiers(rawValue: 2))  // ⌥⌘E
    let event = makeEvent(
      characters: "´",
      charactersIgnoringModifiers: "e",
      flags: [.command, .option])
    XCTAssertTrue(cmd.matches(event))
  }

  func testFallsBackToCharactersWhenIgnoringModifiersIsEmpty() {
    let cmd = MenuItemCommand(character: "C", modifiers: Modifiers(rawValue: 0))
    let event = makeEvent(
      characters: "c",
      charactersIgnoringModifiers: "",
      flags: [.command])
    XCTAssertTrue(cmd.matches(event))
  }

  func testDoesNotMatchOnDifferentModifiers() {
    let cmd = MenuItemCommand(character: "C", modifiers: Modifiers(rawValue: 0))  // ⌘C
    let shifted = makeEvent(characters: "c", flags: [.command, .shift])
    XCTAssertFalse(cmd.matches(shifted))
  }

  func testDoesNotMatchOnDifferentCharacter() {
    let cmd = MenuItemCommand(character: "C", modifiers: Modifiers(rawValue: 0))
    let event = makeEvent(characters: "v", flags: [.command])
    XCTAssertFalse(cmd.matches(event))
  }

  func testCommandWithoutShortcutNeverMatches() {
    let cmd = MenuItemCommand(character: "", modifiers: Modifiers.noCommand)
    let event = makeEvent(characters: "c", flags: [.command])
    XCTAssertFalse(cmd.matches(event))
  }
}
