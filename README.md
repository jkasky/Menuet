# Menuet

A macOS menu-bar utility that lets you search and invoke any menu item in the
frontmost app via a global hotkey, plus a cheatsheet panel that displays every
keyboard shortcut available in that app.

Built on the macOS Accessibility API. Runs as an `LSUIElement` (no Dock icon).

## Build & Test

The Xcode project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/xcodegen).
`project.pbxproj` is gitignored — run `xcodegen generate` after cloning or editing `project.yml`.

```sh
# One-time setup (also run after editing project.yml)
brew install xcodegen
xcodegen generate

# Build
xcodebuild -project Menuet.xcodeproj -scheme Menuet -configuration Debug build

# Test
xcodebuild -project Menuet.xcodeproj -scheme Menuet test
```

For a signed local build, add your Apple Team ID to `Menuet.local.xcconfig`
(gitignored):

```
DEVELOPMENT_TEAM = <your Apple Team ID>
```

CI builds with `CODE_SIGNING_ALLOWED=NO` and needs no team.

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
