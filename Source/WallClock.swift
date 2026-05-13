//
//  WallClock.swift
//  Menuet
//
//  Time source consulted by the menu walker for deadline checks. The
//  protocol exists so tests can substitute a `VirtualClock` and advance
//  time deterministically; production uses `SystemClock`.
//
//  We intentionally avoid Swift's stdlib `Clock` protocol — its async
//  flavor (`sleep(until:)`, `Instant`) would complicate the synchronous
//  walker for no gain.
//

import Foundation


protocol WallClock {

  func now() -> Date

}


struct SystemClock: WallClock {

  func now() -> Date { Date() }

}
