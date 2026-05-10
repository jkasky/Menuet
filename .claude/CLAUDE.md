# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

For the architectural overview — layers, critical invariants, latency bounds,
concurrency story, trust prompt — see [`ARCHITECTURE.md`](../ARCHITECTURE.md)
at the repo root.

## Build & Test

The Xcode project is `Menuet.xcodeproj` and the scheme is `Menuet`.

```sh
# Build
xcodebuild -project Menuet.xcodeproj -scheme Menuet -configuration Debug build

# List schemes (when in doubt)
xcodebuild -project Menuet.xcodeproj -list

# Run all tests
xcodebuild -project Menuet.xcodeproj -scheme Menuet test

# Single test (XCTest)
xcodebuild -project Menuet.xcodeproj -scheme Menuet test \
  -only-testing:MenuetTests/AXMenuWalkerTests/testWalkBailsAtDeadline
```

SourceKit frequently emits cross-file `Cannot find type/in scope` diagnostics
for symbols defined in sibling files in `Source/`. These are resolution noise
from an out-of-sync index, not real errors. Trust `xcodebuild` over the
diagnostic stream.
