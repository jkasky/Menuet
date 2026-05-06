//
//  FuzzyMatchTests.swift
//  MenuetTests
//
//

import XCTest

class FuzzyMatchTest: XCTestCase {

  func testEmptyQueryReturnsNil() {
    XCTAssertNil(FuzzyMatch.score(query: "", candidate: "Copy", caseSensitive: false))
  }

  func testEmptyCandidateReturnsNil() {
    XCTAssertNil(FuzzyMatch.score(query: "c", candidate: "", caseSensitive: false))
  }

  func testQueryMustAppearInOrder() {
    XCTAssertNotNil(FuzzyMatch.score(query: "Cp", candidate: "Copy", caseSensitive: false))
    XCTAssertNil(FuzzyMatch.score(query: "oC", candidate: "Copy", caseSensitive: true))
  }

  func testNoMatchReturnsNil() {
    XCTAssertNil(FuzzyMatch.score(query: "xyz", candidate: "Copy", caseSensitive: false))
  }

  func testCaseSensitiveFlag() {
    XCTAssertNotNil(FuzzyMatch.score(query: "co", candidate: "Copy", caseSensitive: false))
    XCTAssertNil(FuzzyMatch.score(query: "co", candidate: "Copy", caseSensitive: true))
    XCTAssertNotNil(FuzzyMatch.score(query: "Co", candidate: "Copy", caseSensitive: true))
  }

  func testPrefixOutranksMidString() {
    let prefix = FuzzyMatch.score(query: "co", candidate: "Copy", caseSensitive: false)!
    let mid = FuzzyMatch.score(query: "co", candidate: "Open Copy", caseSensitive: false)!
    XCTAssertGreaterThan(prefix.score, mid.score)
  }

  func testWordBoundaryOutranksScattered() {
    let boundary = FuzzyMatch.score(query: "of", candidate: "Open File", caseSensitive: false)!
    let scattered = FuzzyMatch.score(query: "of", candidate: "Code of conduct", caseSensitive: false)!
    XCTAssertGreaterThan(boundary.score, scattered.score)
  }

  func testConsecutiveOutranksScattered() {
    let consecutive = FuzzyMatch.score(query: "copy", candidate: "Copy", caseSensitive: false)!
    let scattered = FuzzyMatch.score(query: "copy", candidate: "Cancel Operation Pyx Yarn", caseSensitive: false)!
    XCTAssertGreaterThan(consecutive.score, scattered.score)
  }

  func testShorterCandidateOutranksLonger() {
    let shorter = FuzzyMatch.score(query: "co", candidate: "Copy", caseSensitive: false)!
    let longer = FuzzyMatch.score(query: "co", candidate: "Copy Special Long Name", caseSensitive: false)!
    XCTAssertGreaterThan(shorter.score, longer.score)
  }

  func testCamelCaseBonus() {
    let camel = FuzzyMatch.score(query: "of", candidate: "OpenFolder", caseSensitive: false)!
    let nonCamel = FuzzyMatch.score(query: "of", candidate: "openfolder", caseSensitive: false)!
    XCTAssertGreaterThan(camel.score, nonCamel.score)
  }

  func testMatchedIndicesPositions() {
    let match = FuzzyMatch.score(query: "cp", candidate: "Copy", caseSensitive: false)!
    XCTAssertEqual(match.matchedIndices, [0, 2])
  }

  func testUnicodeSafety() {
    XCTAssertNotNil(FuzzyMatch.score(query: "é", candidate: "café", caseSensitive: false))
    XCTAssertNil(FuzzyMatch.score(query: "z", candidate: "café", caseSensitive: false))
  }

  func testFullMatchWordBoundary() {
    let withSeparator = FuzzyMatch.score(query: "n", candidate: "File > New", caseSensitive: false)!
    let withoutSeparator = FuzzyMatch.score(query: "n", candidate: "Filename", caseSensitive: false)!
    XCTAssertGreaterThan(withSeparator.score, withoutSeparator.score)
  }
}
