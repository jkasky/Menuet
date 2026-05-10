//
//  IndexProviderTests.swift
//  MenuetTests
//

import XCTest


@MainActor
class IndexProviderTrustTests: XCTestCase {

  func testRefreshFlagsUntrustedAndSkipsWalk() {
    let axClient = FakeAXClient()
    axClient.trusted = false
    // FakeAXApplication's menuBar is nil, so if refresh ever reached the
    // walk it would still complete cleanly — but `isTrusted` becoming
    // false is the signal that the early-return ran.
    let provider = IndexProvider(axClient: axClient)

    provider.refresh()

    XCTAssertFalse(provider.isTrusted)
    XCTAssertNil(provider.currentApp)
    XCTAssertEqual(provider.index.size, 0)
  }

  func testRefreshFlipsBackToTrustedOnceGranted() {
    let axClient = FakeAXClient()
    axClient.trusted = false
    let provider = IndexProvider(axClient: axClient)
    provider.refresh()
    XCTAssertFalse(provider.isTrusted)

    axClient.trusted = true
    provider.refresh()

    XCTAssertTrue(provider.isTrusted)
  }
}
