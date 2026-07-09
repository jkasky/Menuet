//
//  MenuItemCommand.swift
//  MenuetTests
//
//

import XCTest

class MenuItemCommandTest: XCTestCase {

  func testNormalCommandModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.command])
    XCTAssertEqual(c.stringValue, "⌘C")
  }

  func testShiftAndCommandModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.shift, .command])
    XCTAssertEqual(c.stringValue, "⇧⌘C")
  }

  func testOptionAndCommandModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.option, .command])
    XCTAssertEqual(c.stringValue, "⌥⌘C")
  }

  func testOptionShiftAndCommandModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.option, .shift, .command])
    XCTAssertEqual(c.stringValue, "⌥⇧⌘C")
  }

  func testControlAndCommandModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.control, .command])
    XCTAssertEqual(c.stringValue, "⌃⌘C")
  }

  func testControlShiftAndCommandModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.control, .shift, .command])
    XCTAssertEqual(c.stringValue, "⌃⇧⌘C")
  }

  func testControlOptionAndCommandModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.control, .option, .command])
    XCTAssertEqual(c.stringValue, "⌃⌥⌘C")
  }

  func testControlOptionShiftAndCommandModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.control, .option, .shift, .command])
    XCTAssertEqual(c.stringValue, "⌃⌥⇧⌘C")
  }

  func testNoCommandModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [])
    XCTAssertEqual(c.stringValue, "C")
  }

  func testShiftModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.shift])
    XCTAssertEqual(c.stringValue, "⇧C")
  }

  func testOptionModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.option])
    XCTAssertEqual(c.stringValue, "⌥C")
  }

  func testOptionAndShiftModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.option, .shift])
    XCTAssertEqual(c.stringValue, "⌥⇧C")
  }

  func testControlModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.control])
    XCTAssertEqual(c.stringValue, "⌃C")
  }

  func testControlAndShiftModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.control, .shift])
    XCTAssertEqual(c.stringValue, "⌃⇧C")
  }

  func testControlAndOptionModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.control, .option])
    XCTAssertEqual(c.stringValue, "⌃⌥C")
  }

  func testControlOptionAndShiftModifier() {
    let c = MenuItemCommand(character: "C", modifiers: [.control, .option, .shift])
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
    let cmd = MenuItemCommand(character: "C", modifiers: [.command])
    let event = makeEvent(characters: "c", flags: [.command])
    XCTAssertTrue(cmd.matches(event))
  }

  func testIsCaseInsensitive() {
    let cmd = MenuItemCommand(character: "C", modifiers: [.command])
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
    let cmd = MenuItemCommand(character: "E", modifiers: [.option, .command])
    let event = makeEvent(
      characters: "´",
      charactersIgnoringModifiers: "e",
      flags: [.command, .option])
    XCTAssertTrue(cmd.matches(event))
  }

  func testFallsBackToCharactersWhenIgnoringModifiersIsEmpty() {
    let cmd = MenuItemCommand(character: "C", modifiers: [.command])
    let event = makeEvent(
      characters: "c",
      charactersIgnoringModifiers: "",
      flags: [.command])
    XCTAssertTrue(cmd.matches(event))
  }

  func testDoesNotMatchOnDifferentModifiers() {
    let cmd = MenuItemCommand(character: "C", modifiers: [.command])
    let shifted = makeEvent(characters: "c", flags: [.command, .shift])
    XCTAssertFalse(cmd.matches(shifted))
  }

  func testDoesNotMatchOnDifferentCharacter() {
    let cmd = MenuItemCommand(character: "C", modifiers: [.command])
    let event = makeEvent(characters: "v", flags: [.command])
    XCTAssertFalse(cmd.matches(event))
  }

  func testCommandWithoutShortcutNeverMatches() {
    let cmd = MenuItemCommand(character: "", modifiers: [])
    let event = makeEvent(characters: "c", flags: [.command])
    XCTAssertFalse(cmd.matches(event))
  }

  // MARK: - Glyph / function-key shortcuts

  // The display `character` for a function key ("F5") is never what the
  // keyboard delivers (NSF5FunctionKey); matching goes through
  // `keyEquivalent`. AppKit also stamps `.function` on the event, which the
  // shortcut doesn't carry, so it must be masked off.

  func testMatchesFunctionKeyWithCommand() {
    let f5 = KeyGlyph.F5.keyEquivalent!
    let cmd = MenuItemCommand(
      character: "F5", modifiers: [.command], keyEquivalent: f5)
    let event = makeEvent(characters: f5, flags: [.command, .function])
    XCTAssertTrue(cmd.matches(event))
  }

  func testMatchesBareFunctionKey() {
    let f5 = KeyGlyph.F5.keyEquivalent!
    let cmd = MenuItemCommand(character: "F5", modifiers: [], keyEquivalent: f5)
    // AppKit sets `.function` even with no shortcut modifiers.
    let event = makeEvent(characters: f5, flags: [.function])
    XCTAssertTrue(cmd.matches(event))
  }

  func testMatchesReturnGlyph() {
    let cmd = MenuItemCommand(
      character: KeyGlyph.Return.characters, modifiers: [], keyEquivalent: "\r")
    // Return doesn't fall in the NSFunctionKey range — no `.function` flag.
    let event = makeEvent(characters: "\r", flags: [])
    XCTAssertTrue(cmd.matches(event))
  }

  func testMatchesDeleteGlyph() {
    let cmd = MenuItemCommand(
      character: KeyGlyph.Delete.characters, modifiers: [.command],
      keyEquivalent: "\u{7F}")
    let event = makeEvent(characters: "\u{7F}", flags: [.command])
    XCTAssertTrue(cmd.matches(event))
  }

  func testMatchesArrowGlyph() {
    let down = KeyGlyph.Down.keyEquivalent!
    let cmd = MenuItemCommand(
      character: KeyGlyph.Down.characters, modifiers: [.command],
      keyEquivalent: down)
    // Arrow keys carry both `.function` and `.numericPad`; both are ignored.
    let event = makeEvent(characters: down, flags: [.command, .function, .numericPad])
    XCTAssertTrue(cmd.matches(event))
  }

  func testFunctionKeyDoesNotMatchDifferentFunctionKey() {
    let cmd = MenuItemCommand(
      character: "F5", modifiers: [], keyEquivalent: KeyGlyph.F5.keyEquivalent!)
    let event = makeEvent(characters: KeyGlyph.F6.keyEquivalent!, flags: [.function])
    XCTAssertFalse(cmd.matches(event))
  }

  func testFunctionKeyRespectsRealModifiers() {
    let f5 = KeyGlyph.F5.keyEquivalent!
    let cmd = MenuItemCommand(character: "F5", modifiers: [], keyEquivalent: f5)
    // ⇧F5 event should not match a bare-F5 shortcut.
    let event = makeEvent(characters: f5, flags: [.function, .shift])
    XCTAssertFalse(cmd.matches(event))
  }

  // Regression: a Globe (🌐) modifier on a *printable* key sets `.function`
  // too, but goes through the character path where the bit must survive on
  // both sides.
  func testGlobeModifierOnLetterStillMatches() {
    let cmd = MenuItemCommand(character: "F", modifiers: [.function])
    let event = makeEvent(characters: "f", flags: [.function])
    XCTAssertTrue(cmd.matches(event))
  }
}


final class FakeMenuItemTarget: MenuItemTarget, @unchecked Sendable {
  var hasFocusedWindow: Bool = false
  let debugDescription = "fake-target"
}


final class FakePressTarget: MenuItemPressTarget {
  var isEnabled: Bool = false
  private(set) var pressCount = 0
  func press() { pressCount += 1 }
}


@MainActor
class MenuItemCommandPerformWhenReadyTests: XCTestCase {

  // Spin the main runloop until `predicate` returns true, or `timeout` elapses.
  // The poll loop schedules ticks via `DispatchQueue.main.asyncAfter`, so the
  // runloop must be alive for them to fire.
  private func wait(
    upTo timeout: TimeInterval,
    until predicate: @autoclosure () -> Bool
  ) {
    let deadline = Date().addingTimeInterval(timeout)
    while !predicate() && Date() < deadline {
      RunLoop.main.run(until: Date().addingTimeInterval(0.01))
    }
  }

  func testPressesOnceBothSignalsReady() {
    let target = FakeMenuItemTarget()
    let press = FakePressTarget()
    let cmd = MenuItemCommand(character: "M", modifiers: [.command], delegate: press)

    cmd.performWhenReady(target: target, timeout: 1.0, pollInterval: 0.02)
    // Neither signal is ready — poll should not press yet.
    wait(upTo: 0.15, until: press.pressCount > 0)
    XCTAssertEqual(press.pressCount, 0)

    // Flip both signals; next tick should press.
    target.hasFocusedWindow = true
    press.isEnabled = true
    wait(upTo: 0.5, until: press.pressCount > 0)
    XCTAssertEqual(press.pressCount, 1)
  }

  func testDoesNotPressUntilFocusedWindowFlips() {
    let target = FakeMenuItemTarget()
    let press = FakePressTarget()
    press.isEnabled = true  // "Move to Display" — enabled from the start.
    let cmd = MenuItemCommand(character: "M", modifiers: [.command], delegate: press)

    cmd.performWhenReady(target: target, timeout: 1.0, pollInterval: 0.02)
    wait(upTo: 0.15, until: press.pressCount > 0)
    XCTAssertEqual(press.pressCount, 0,
      "isEnabled alone should not unlock the press — focused window must restore first")

    target.hasFocusedWindow = true
    wait(upTo: 0.5, until: press.pressCount > 0)
    XCTAssertEqual(press.pressCount, 1)
  }

  func testFallsThroughAtDeadline() {
    let target = FakeMenuItemTarget()  // hasFocusedWindow stays false.
    let press = FakePressTarget()      // isEnabled stays false.
    let cmd = MenuItemCommand(character: "M", modifiers: [.command], delegate: press)

    cmd.performWhenReady(target: target, timeout: 0.1, pollInterval: 0.02)
    wait(upTo: 0.5, until: press.pressCount > 0)
    XCTAssertEqual(press.pressCount, 1,
      "Should fire once at the deadline even if signals never flip")
  }

  func testDoesNotPressTwice() {
    let target = FakeMenuItemTarget()
    let press = FakePressTarget()
    target.hasFocusedWindow = true
    press.isEnabled = true
    let cmd = MenuItemCommand(character: "M", modifiers: [.command], delegate: press)

    cmd.performWhenReady(target: target, timeout: 0.2, pollInterval: 0.02)
    wait(upTo: 0.4, until: false)  // burn through any extra scheduled ticks
    XCTAssertEqual(press.pressCount, 1)
  }

  func testNilTargetPressesImmediatelyOnEnabled() {
    let press = FakePressTarget()
    press.isEnabled = true
    let cmd = MenuItemCommand(character: "M", modifiers: [.command], delegate: press)

    cmd.performWhenReady(target: nil, timeout: 0.2, pollInterval: 0.02)
    wait(upTo: 0.2, until: press.pressCount > 0)
    XCTAssertEqual(press.pressCount, 1)
  }
}
