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

## Diagnostics: `menutil`

`menutil` is a command-line menu walker built from the same Accessibility
layer as the app — it dumps any app's menu tree as text or JSON, with the
same fuzzy filter Menuet search uses. Useful for debugging AX behavior.

```sh
# Separate scheme/target
xcodebuild -project Menuet.xcodeproj -scheme menutil build

menutil apps                                      # list targetable apps
menutil walk --app <bundle-id> --filter <query>
menutil walk --app <bundle-id> --ax --json
menutil --help
```

First run needs a one-time Accessibility grant; it's code-signed, so the grant
persists across rebuilds.
