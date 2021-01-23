//
//  Preferences.swift
//  Menumate
//
//  Created by Jesse Kasky on 12/13/20.
//  Copyright © 2020 Codjax. All rights reserved.
//

import Cocoa
import Carbon
import Foundation

struct ShortCut {
  public let characters: String
  public let keyCode: UInt16
  public let modifierFlags: NSEvent.ModifierFlags
}

extension UserDefaults  {
  
  @objc dynamic var searchMenuShortcut: Bool {
    get {return true}
    set {}
  }
  
  var searchMenuShortcutValue: ShortCut? {
    get {
      let data = dictionary(forKey: "searchMenuShortcut")
      guard data != nil else { return nil }
      return ShortCut(
        characters: data!["charactersIgnoringModifiers"] as! String,
        keyCode: data!["keyCode"] as! UInt16,
        modifierFlags: NSEvent.ModifierFlags(rawValue: data!["modifierFlags"] as! UInt))
    }
    set {
      var characters: String  {
        guard
          let currentKeyboard = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
          let layoutDataPtr = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData)
        else {
          return ""
        }

        let maxCharacterLength = 4
        let modifierKeyState: UInt32 = 0
        var keysDown: UInt32 = 0
        var eventCharacters = [UniChar](repeating: 0, count: maxCharacterLength)
        var actualCharacterLength: Int = 0

        let layoutData = Unmanaged<CFData>.fromOpaque(layoutDataPtr).takeUnretainedValue() as Data
        let keyTranslationErr: OSStatus = layoutData.withUnsafeBytes {
            (unsafeLayoutData: UnsafeRawBufferPointer) -> OSStatus in
          return UCKeyTranslate(
            unsafeLayoutData.bindMemory(to: UCKeyboardLayout.self).baseAddress,
            newValue!.keyCode,
            UInt16(kUCKeyActionDisplay),
            modifierKeyState,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &keysDown,
            maxCharacterLength,
            &actualCharacterLength,
            &eventCharacters)
        }

        guard keyTranslationErr == noErr else {
          return ""
        }

        return CFStringCreateWithCharacters(kCFAllocatorDefault, eventCharacters, 1) as String
      }
      
      let data: [String: Any] = [
        "characters": "\(characters)",
        "charactersIgnoringModifiers": characters,
        "keyCode": newValue!.keyCode,
        "modifierFlags": newValue!.modifierFlags.rawValue
      ]
      set(data, forKey: "searchMenuShortcut")
    }
  }
}
