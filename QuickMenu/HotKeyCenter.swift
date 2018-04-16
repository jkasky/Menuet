//
//  HotKeyCenter.swift
//  QuickMenu
//
//  Created by Jesse Kasky on 1/23/18.
//  Copyright © 2018 Codjax. All rights reserved.
//

import Carbon
import Cocoa
import Foundation


struct HotKey: Hashable {
  var hashValue: Int {
    // Modifier flags are set on 16th bit and higher so XOR with the UInt16 produces
    // an Int that has the keyCode in 0-15 and the modifier in 16-31 bits. The hashCode
    // on Int types returns the value.
    return keyCode.hashValue ^ modifierFlags.rawValue.hashValue
  }

  static func ==(left: HotKey, right: HotKey) -> Bool {
    return (left.keyCode == right.keyCode &&
            left.modifierFlags == right.modifierFlags)
  }

  public let keyCode: Int
  public let modifierFlags: NSEvent.ModifierFlags
  public let task: (NSEvent) -> Void

  init(_ keyCode: Int,
       _ modifierFlags: NSEvent.ModifierFlags,
       _ task: @escaping (NSEvent) -> Void) {
    self.keyCode = keyCode
    self.modifierFlags = modifierFlags
    self.task = task
  }
}


/** Global HotKey center for managing application level hot keys. */
class HotKeyCenter {

  static let shared = HotKeyCenter()

  fileprivate var registeredHotKeys: Dictionary<Int, HotKey>

  private var eventHandler: EventHandlerRef?

  private init() {
    registeredHotKeys = Dictionary<Int, HotKey>()

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
    guard registeredHotKeys[hotKey.hashValue] == nil else {
      return
    }

    let hotKeyID = EventHotKeyID(
      signature: "GHKC".fourCharCodedType,
      id: UInt32(hotKey.hashValue))
    var eventHotKey: EventHotKeyRef? = nil

    RegisterEventHotKey(
      UInt32(hotKey.keyCode),
      UInt32(hotKey.modifierFlags.carbonValue),
      hotKeyID,
      GetApplicationEventTarget(),
      OptionBits(0),
      &eventHotKey)

    registeredHotKeys[hotKey.hashValue] = hotKey
  }

  public func unregister(_ hotKey: HotKey) {
    registeredHotKeys.removeValue(forKey: hotKey.hashValue)
  }

  public func unregisterAll() {
    for hotKey in registeredHotKeys.values {
      unregister(hotKey)
    }
  }
}


private func globalHotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    anEvent: EventRef?,
    userData: UnsafeMutableRawPointer?) -> OSStatus {

  var hotKeyID = EventHotKeyID()
  GetEventParameter(
    anEvent,
    EventParamName(kEventParamDirectObject),
    UInt32(typeEventHotKeyID),
    nil,
    MemoryLayout.size(ofValue: hotKeyID),
    nil,
    &hotKeyID)

  let hotKey = HotKeyCenter.shared.registeredHotKeys[Int(hotKeyID.id)]
  let event = NSEvent(eventRef: UnsafeMutablePointer(anEvent!))
  hotKey?.task(event!)

  NSLog("Received HotKey (%d, %d)", hotKeyID.signature, hotKeyID.id)

  return OSStatus(eventNotHandledErr)
}


fileprivate extension NSEvent.ModifierFlags {
  var carbonValue: UInt32 {
    var flags: UInt32 = 0
    if contains(.command) {
      flags |= UInt32(cmdKey)
    }
    if contains(.control) {
      flags |= UInt32(controlKey)
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


fileprivate extension String {
  var fourCharCodedType: UInt32 {
    return UTGetOSTypeFromString(self as CFString)
  }
}
