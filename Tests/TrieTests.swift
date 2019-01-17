//
//  TrieTest.swift
//  MenuFinderTests
//
//  Created by Jesse Kasky on 4/25/18.
//  Copyright © 2018 Codjax. All rights reserved.
//

import XCTest

class TrieTest: XCTestCase {

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testEmptyTrie() {
    XCTAssertEqual(Trie<Int>().find(sequence: ""), [])
  }

  func testNoMatches() {
    let trie = Trie<Int>()
    trie.insert(label: "apple", value: 0)
    trie.insert(label: "orange", value: 1)
    XCTAssertEqual(trie.find(sequence: "ba"), [])
  }

  func testFindWithFullValue() {
    let trie = Trie<Int>()
    trie.insert(label: "monkey", value: 1)
    trie.insert(label: "zebra", value: 2)
    trie.insert(label: "zap", value: 3)

    XCTAssertEqual(trie.find(sequence: "zebra"), [2])
  }

  func testFindWithEachCharacter() {
    let trie = Trie<String>()
    let string = "abc"
    trie.insert(label: string, value: string)
    for c in string {
      XCTAssertEqual(trie.find(sequence: String(c)), [string])
    }
  }

  func testFindsAllWithSingleCharacter() {
    let trie = Trie<Int>()
    trie.insert(label: "apple", value: 1)
    trie.insert(label: "banana", value: 2)
    trie.insert(label: "kiwi", value: 3)
    trie.insert(label: "orange", value: 4)

    XCTAssertEqual(trie.find(sequence: "p"), [1])
    XCTAssertEqual(trie.find(sequence: "a"), [1, 2, 4])
    XCTAssertEqual(trie.find(sequence: "e"), [1, 4])
  }

  func testFindWithTrailingCharacter() {
    let trie = Trie<Int>()
    trie.insert(label: "lion", value: 1)
    trie.insert(label: "tiger", value: 2)
    trie.insert(label: "bear", value: 3)
    trie.insert(label: "baboon", value: 4)

    XCTAssertEqual(trie.find(sequence: "r"), [3, 2])
  }

  func testDoesNotFindWithDuplicateCharacterSequence() {
    let trie = Trie<Int>()
    trie.insert(label: "pole", value: 1)

    XCTAssertEqual(trie.find(sequence: "pp"), [])
  }

  func testFindWithDuplicateSequence() {
    let trie = Trie<Int>()
    trie.insert(label: "apple", value: 1)
    trie.insert(label: "apps", value: 2)
    trie.insert(label: "pole", value: 3)
    trie.insert(label: "pop", value: 4)
    trie.insert(label: "pps", value: 5)

    XCTAssertEqual(trie.find(sequence:"pp"), [1, 2, 4, 5])
  }

  func testFindResultsSortedAlphabetically() {
    let trie = Trie<Int>()
    trie.insert(label: "the world", value: 2)
    trie.insert(label: "the world is", value: 3)
    trie.insert(label: "is the world round", value:1)
    trie.insert(label: "world", value: 4)
    trie.insert(label: "is the world", value: 0)

    XCTAssertEqual(trie.find(sequence: "w"), [0, 1, 2, 3, 4])
  }

  func testFindWithNonAdjacentSequence() {
    let trie = Trie<Int>()
    trie.insert(label: "file > new", value: 0)
    trie.insert(label: "file > open", value: 1)
    trie.insert(label: "find > next", value: 2)
    trie.insert(label: "find > previous", value: 3)

    XCTAssertEqual(trie.find(sequence:"fp"), [1, 3])
    XCTAssertEqual(trie.find(sequence:"fw"), [0])
    XCTAssertEqual(trie.find(sequence:"fdt"), [2])
  }
}
