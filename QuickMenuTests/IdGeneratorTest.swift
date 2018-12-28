//
//  IdGeneratorTest.swift
//  QuickMenuTests
//
//  Created by Jesse Kasky on 2018-12-28.
//  Copyright © 2018 Codjax. All rights reserved.
//

import XCTest

class IdGeneratorTest: XCTestCase {

  func testIdGenerator() {
    var generator = IdGenerator<UInt>()
    for i in 1..<100 {
      XCTAssertEqual(i, Int(generator.next()))
    }
  }
}
