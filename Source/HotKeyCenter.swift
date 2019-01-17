//
//  HotKeyCenter.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 1/23/18.
//  Copyright © 2018 Codjax. All rights reserved.
//

import Carbon
import Cocoa
import Foundation


/**
 * Generates IDs from 1 to T.max for any unsigned integer type.
 */
struct IdGenerator<T: UnsignedInteger> {
  
  private var value: T = 1
  
  mutating func next() -> T {
    defer {value += 1}
    return value
  }
}


/**
 * A structure that contains key code, modifiers, and task for a HotKey.
 */
public struct HotKey: Hashable {
  
  private static var idGenerator = IdGenerator<UInt32>()

  public var hashValue: Int {
    var hasher = Hasher()
    hasher.combine(keyCode)
    hasher.combine(modifierFlags.rawValue)
    return hasher.finalize()
  }

  public static func ==(left: HotKey, right: HotKey) -> Bool {
    return (left.keyCode == right.keyCode &&
            left.modifierFlags == right.modifierFlags)
  }

  /**
   * Application specific unique ID of HotKey.
   *
   * Only UInt32.max HotKey's can be registered per application.
   */
  public let id: UInt32
  public let keyCode: Int
  public let modifierFlags: NSEvent.ModifierFlags
  public let task: (NSEvent) -> Void

  public init(_ keyCode: Int,
              _ modifierFlags: NSEvent.ModifierFlags,
              _ task: @escaping (NSEvent) -> Void) {
    self.id = HotKey.idGenerator.next()
    self.keyCode = keyCode
    self.modifierFlags = modifierFlags
    self.task = task
  }
}


/**
 * Global HotKey center for managing application level hot keys.
 */
public class HotKeyCenter {

  static let shared = HotKeyCenter()

  fileprivate var registeredHotKeys: Dictionary<UInt32, RegisteredHotKey>

  private var eventHandler: EventHandlerRef?

  private init() {
    registeredHotKeys = Dictionary<UInt32, RegisteredHotKey>()

    var eventSpec = EventTypeSpec(
      eventClass: UInt32(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed))

    let status = InstallEventHandler(
      GetApplicationEventTarget(),
      globalHotKeyHandler,
      1,
      &eventSpec,
      nil,
      &eventHandler)

    if (status != noErr) {
      NSLog("Failed to install global event handler: %d", status)
    }
  }

  deinit {
    if (eventHandler != nil) {
      let status: OSStatus = RemoveEventHandler(eventHandler)
      if (status != noErr) {
        NSLog("Failed to remove global event handler: %d", status)
      }
    }
  }

  public func register(_ hotKey: HotKey) {
    guard registeredHotKeys[hotKey.id] == nil else {
      return
    }

    let hotKeyID = EventHotKeyID(
      signature: "GHKC".fourCharCodeType,
      id: hotKey.id)
    var eventHotKey: EventHotKeyRef? = nil

    let status = RegisterEventHotKey(
      UInt32(hotKey.keyCode),
      UInt32(hotKey.modifierFlags.carbonValue),
      hotKeyID,
      GetApplicationEventTarget(),
      OptionBits(0),
      &eventHotKey)

    if (status == noErr && eventHotKey != nil) {
      registeredHotKeys[hotKey.id] = RegisteredHotKey(
        hotKey: hotKey, registeredRef: eventHotKey!)
    }
  }

  public func unregister(_ hotKey: HotKey) {
    let value = registeredHotKeys.removeValue(forKey: hotKey.id)
    guard value != nil else {
      return
    }
    UnregisterEventHotKey(value?.registeredRef)
  }

  public func unregisterAll() {
    for r in registeredHotKeys.values {
      unregister(r.hotKey)
    }
  }

  fileprivate func lookup(_ value: EventHotKeyID) -> HotKey? {
    return registeredHotKeys[value.id]?.hotKey
  }
}


/**
 * A structure that contains HotKey and registered Carbon reference.
 */
internal struct RegisteredHotKey: Hashable {
  let hotKey: HotKey

  // Reference to the Carbon event registered for the global hotkey.
  let registeredRef: EventHotKeyRef
}


/**
 * Dispatches event to registered HotKey handler.
 */
fileprivate func globalHotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    anEvent: EventRef?,
    userData: UnsafeMutableRawPointer?) -> OSStatus {

  var hotKeyID = EventHotKeyID()
  let status = GetEventParameter(
    anEvent,
    EventParamName(kEventParamDirectObject),
    UInt32(typeEventHotKeyID),
    nil,
    MemoryLayout<EventHotKeyID>.size,
    nil,
    &hotKeyID)

  guard status == noErr else {
    return OSStatus(eventNotHandledErr)
  }

  guard let hotKey = HotKeyCenter.shared.lookup(hotKeyID) else {
    return OSStatus(eventNotHandledErr)
  }

  guard let anEvent = anEvent else {
    return OSStatus(eventNotHandledErr)
  }

  guard let event = NSEvent(eventRef: UnsafeMutablePointer(anEvent)) else {
    return OSStatus(eventNotHandledErr)
  }

  let keyEvent = NSEvent.keyEvent(
    with: NSEvent.EventType.keyUp,
    location: event.locationInWindow,
    modifierFlags: event.modifierFlags,
    timestamp: event.timestamp,
    windowNumber: -1,
    context:nil,
    characters:"",
    charactersIgnoringModifiers: "",
    isARepeat: false,
    keyCode: UInt16(hotKey.keyCode))!

   hotKey.task(keyEvent)

  return OSStatus(noErr)
}


internal extension NSEvent.ModifierFlags {

  /**
   * The Cocoa modifier flag value as a Carbon event modifier value.
   *
   * See Events.h and CarbonEvents.h form the Carbon framework for all the
   * carbon event modifier equivalents.
   */
  var carbonValue: UInt32 {
    var flags: UInt32 = 0
    if contains(.capsLock) {
      flags |= UInt32(alphaLock)
    }
    if contains(.command) {
      flags |= UInt32(cmdKey)
    }
    if contains(.control) {
      flags |= UInt32(controlKey)
    }
    if contains(.function) {
      flags |= UInt32(kEventKeyModifierFnMask)
    }
    if contains(.numericPad) {
      flags |= UInt32(kEventKeyModifierNumLockMask)
    }
    if contains(.option) {
      flags |= UInt32(optionKey)
    }
    if contains(.shift) {
      flags |= UInt32(shiftKey)
    }
    return flags
  }
}


internal extension String {

  /**
   * The String value as a four character code type.
   */
  var fourCharCodeType: UInt32 {
    return UTGetOSTypeFromString(self as CFString)
  }
}
