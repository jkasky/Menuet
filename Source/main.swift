//
//  main.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 2019-05-27.
//  Copyright © 2019 Codjax. All rights reserved.
//

import AppKit


#if DEBUG

// When running DEBUG build use TestingAppDelegate to prevent the normal
// delegate methods from being called. Tests are built as a bundle then run
// using the application as the test harness. We want to prevent doing things
// when testing like making the process trusted for accessibility.

class TestingAppDelegate: NSResponder, NSApplicationDelegate {}

if NSClassFromString("XCTestCase") != nil {
  let delegate = TestingAppDelegate()
  NSApplication.shared.delegate = delegate
  NSApp.run()
} else {
  _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
}

#else

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)

#endif
