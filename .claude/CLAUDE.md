# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

The Xcode scheme is `"MenuBar Pro"` (with a space) — not `MenuBarPro`. The project file is `MenuBarPro.xcodeproj`.

```sh
# Build
xcodebuild -project MenuBarPro.xcodeproj -scheme "MenuBar Pro" -configuration Debug build

# List schemes (when in doubt)
xcodebuild -project MenuBarPro.xcodeproj -list

# Run all tests
xcodebuild -project MenuBarPro.xcodeproj -scheme "MenuBar Pro" test

# Single test (XCTest)
xcodebuild -project MenuBarPro.xcodeproj -scheme "MenuBar Pro" test \
  -only-testing:MenuBarProTests/AXMenuWalkerTests/testWalkSimpleMenu
```

SourceKit frequently emits cross-file `Cannot find type/in scope` diagnostics for symbols defined in sibling files in `Source/`. These are resolution noise from an out-of-sync index, not real errors. Trust `xcodebuild` over the diagnostic stream.

## Architecture

This is an **`LSUIElement` menu-bar utility** (no Dock icon) that lets the user search the menu bar of the **frontmost other app** via a global hotkey, then invoke a chosen menu item — all driven by the macOS Accessibility (AX) API.

### Three layers

1. **AX wrapper (`Source/AX*.swift`)** — typed Swift facade over `ApplicationServices`'s `AXUIElement` C API. `AX.Element`, `AX.Application`, `AX.Attribute`, `AX.Action`, `AX.Role`. `AccessibilityClient` is the protocol entry point, `AXClient` the production impl; both `AXApplication` and `AXElement` accept fakes for unit tests (see `Tests/Fake*.swift`).

2. **Menu indexing (`AXMenu.swift`, `Menu.swift`, `Trie.swift`)** — `AXMenuWalker` traverses `MenuBar → MenuBarItem → Menu → MenuItem` recursively. `AXMenuIndexer` (an `AXMenuVisitor`) extracts title/shortcut/enabled state per leaf and inserts into a `MenuIndex`-backed `Trie<MenuItem>`. `MenuItemCommand.perform()` dispatches via an `AXMenuItemDelegate` that does an `AXPress`, with a path-based fallback (`AXMenuItemPath`) when the captured element is no longer valid.

3. **UI (`MenuBarApp.swift`, `MenuSearchPanel.swift`, `MenuSearchView.swift`)** — SwiftUI `MenuBarExtra` for the status item; `MenuSearchPanel` is an `NSPanel` configured `.nonactivatingPanel + .floating + .moveToActiveSpace + .fullScreenAuxiliary` so it overlays the user's current space without disrupting it. `SearchManager` (`ObservableObject`, singleton via `.shared`) owns `currentApp`, `currentIndex`, query, and results.

### Critical invariant: walk before stealing focus

`SearchManager.activate()` must be called **before** `NSApp.activate()` and `panel.makeKeyAndOrderFront(_:)` in `AppState.showSearchPanel`. Many apps disable selection-dependent menu items (Cut/Copy/etc.) when their key window resigns key — if we walk after that point, those items appear missing. The walk happens once per panel open; `SearchManager.search()` only queries the cached index per keystroke.

### Critical invariant: dismiss → activate target → defer press

`MenuSearchPanel.dismissAndPerform` is the single path for invoking a result (Return, ⌘1–7, matched shortcut). It:
1. Closes the panel (`resignMain()`).
2. Activates the target with `.activateAllWindows` so AppKit restores its previously-key window and first responder.
3. Defers the AX press one runloop tick — NSMenu validation is lazy, so items dependent on first-responder context can still be flagged disabled at the instant of activation. The yield lets the target re-validate.

If you're adding a new way to invoke a result, route it through `dismissAndPerform`.

### Trust prompt

`AppState.makeProcessTrusted` triggers the system Accessibility-permissions prompt on first launch via `AXIsProcessTrustedWithOptions`. Without it, AX queries return nothing.
