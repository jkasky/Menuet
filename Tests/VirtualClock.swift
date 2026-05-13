//
//  VirtualClock.swift
//  MenuetTests
//
//  Mutable clock substitute used by walker tests to advance time without
//  Thread.sleep. Tests share one instance between the walker (via init)
//  and its FakeAXElement inputs (via `clock` + `responseDelay`); each
//  fake attribute access advances the clock, simulating per-call AX
//  latency. This keeps deadline tests deterministic and millisecond-fast.
//

import Foundation


final class VirtualClock: WallClock {

  private var current: Date

  init(start: Date = Date(timeIntervalSince1970: 0)) {
    self.current = start
  }

  func now() -> Date { current }

  func advance(by interval: TimeInterval) {
    current.addTimeInterval(interval)
  }
}
