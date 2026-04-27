# MenuBar Pro

A macOS menu-bar utility that lets you search and invoke any menu item in the
frontmost app via a global hotkey, plus a cheatsheet panel that displays every
keyboard shortcut available in that app.

Built on the macOS Accessibility API. Runs as an `LSUIElement` (no Dock icon).

## Build & Test

The Xcode scheme is `"MenuBar Pro"` (with a space).

```sh
# Build
xcodebuild -project MenuBarPro.xcodeproj -scheme "MenuBar Pro" -configuration Debug build

# Test
xcodebuild -project MenuBarPro.xcodeproj -scheme "MenuBar Pro" test
```

First launch prompts for Accessibility permission, which is required for AX
queries against other apps.

## Known Issues

- **Named menu section headers appear as search results.** For example, in
  Xcode: `Product › Destination › Build` lists "Build" as a section header
  above the destination items. No AX attribute on macOS 14+ distinguishes
  section headers from ordinary menu items — `role`, `subrole`, `enabled`,
  the various `MenuItemCmd*` attrs, and `primaryUIElement` role are all
  identical between section headers and shortcut-less items. Filtering them
  out is not currently possible without false positives.
