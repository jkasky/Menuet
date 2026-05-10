# Architecture

Menuet is an `LSUIElement` macOS menu-bar utility (no Dock icon). A global
hotkey opens a search panel that fuzzy-matches and invokes any menu item in
the frontmost other app; a second hotkey opens a cheatsheet panel that lists
every keyboard shortcut that app exposes. Everything is driven by the macOS
Accessibility (AX) API.

## Three layers

### 1. AX wrapper (`Source/AX*.swift`, `Source/Clock.swift`)

Typed Swift facade over `ApplicationServices`'s `AXUIElement` C API.

- `AX.Element`, `AX.Application`, `AX.Attribute`, `AX.Action`, `AX.Role` —
  protocol-fronted types. `AccessibilityClient` is the entry point;
  `AXClient` is the production conformer. Both `AXApplication` and
  `AXElement` accept fakes for unit tests (see `Tests/Fake*.swift`).
- `Clock` — small protocol consulted by the menu walker for deadline
  checks. `SystemClock` (production) returns `Date()`; `VirtualClock`
  (tests) advances on demand.
- `AXClient.init` sets a per-call AX messaging timeout once at startup
  via the system-wide accessibility object — see "Latency bounds" below.

### 2. Menu indexing (`AXMenu.swift`, `Menu.swift`, `FuzzyMatch.swift`)

- `AXMenuWalker.walk(visitor:deadline:)` traverses
  `MenuBar → MenuBarItem → Menu → MenuItem` recursively in depth-first
  order. The visitor protocol's callback ordering is documented on
  `AXMenuVisitor`.
- `AXMenuIndexer` (an `AXMenuVisitor`) extracts title, shortcut, and
  enabled state per leaf and appends to `MenuIndex`'s flat `[MenuItem]`.
  It delegates path bookkeeping to `MenuPathTracker`, which manages the
  parallel title and position stacks.
- `MenuIndex` exposes `find(query:)` (fuzzy-scored search via
  `FuzzyMatch.score`, an fts_fuzzy_match-style scorer that rewards
  prefix, word-boundary, camelCase, and consecutive-run matches) and
  `itemsWithShortcuts()` (cheatsheet feed). It also carries `isComplete`
  / `isEmpty` flags so views know whether the walk finished.
- `MenuItemCommand.perform()` dispatches via an `AXMenuItemDelegate` that
  does an `AXPress`, with a path-based fallback (`AXMenuItemPath`) when
  the captured element is no longer valid.

### 3. UI (`MenuBarApp.swift`, `Menu*Panel.swift`, `Menu*View.swift`)

- `MenuBarExtra` for the status item.
- `MenuSearchPanel` / `MenuSearchView` — the search-and-invoke flow.
- `MenuCheatsheetPanel` / `MenuCheatsheetView` — the keyboard-shortcut
  reference grid (with live modifier-key filtering and incremental
  search).
- Both panels are `NSPanel`s configured
  `.nonactivatingPanel + .floating + .moveToActiveSpace + .fullScreenAuxiliary`
  so they overlay the user's current space without disrupting it.
- `PanelChrome.swift` houses shared chrome — `PanelBackground`,
  `ShortcutChip`, `NotRespondingView`, `fuzzyHighlight`.

State is split into three narrow `ObservableObject` types, each
`@MainActor`-isolated and singleton via `.shared`:

- `MenuIndexProvider` — owns `currentApp` and `index`. The single source
  of truth for "what menu does the target app have right now"; sessions
  read from it.
- `SearchSession` — owns the search query, results, selection, focus
  trigger, and the blocked-return pulse used by the chip-highlight
  animation.
- `CheatsheetSession` — owns the cheatsheet groups, query, modifier
  filter, match set, and active item.

`AppState` (also `@MainActor`) wires the global hotkeys to the panels
and bridges KeyboardShortcuts callbacks via `MainActor.assumeIsolated`.

## Critical invariant: walk before stealing focus

`MenuIndexProvider.shared.refresh()` must be called **before** the panel
takes key focus in `AppState.showSearchPanel` / `showCheatsheetPanel`.
Many apps disable selection-dependent menu items (Cut/Copy/etc.) when
their key window resigns key — if we walk after that point, those items
appear missing. The walk happens once per panel open; the sessions
query the cached index per keystroke.

## Critical invariant: dismiss → activate target → defer press

`MenuSearchPanel.dismissAndPerform` and the corresponding cheatsheet
flow are the single paths for invoking a result (Return, ⌘1–7, matched
shortcut). They:
1. Close the panel (`resignMain()`).
2. Activate the target with `.activateAllWindows` so AppKit restores its
   previously-key window and first responder.
3. Defer the AX press one runloop tick — NSMenu validation is lazy, so
   items dependent on first-responder context can still be flagged
   disabled at the instant of activation. The yield lets the target
   re-validate.

If you're adding a new way to invoke a result, route it through
`dismissAndPerform`.

## Latency bounds: hung target apps

Hung apps used to freeze Menuet on the hotkey. Two complementary
bounds defend the menu walk:

- **Per-call AX timeout** — `AXClient.init` calls
  `AXUIElementSetMessagingTimeout` on the system-wide accessibility
  object. Default 0.5s, override with
  `defaults write app.menuet axMessagingTimeout -float N`. Bounds any
  single attribute read.
- **Walk-level wall-clock deadline** — `MenuIndexProvider.refresh`
  passes `Date() + axWalkDeadline` to `AXMenuWalker.walk`. The walker
  checks `clock.now() < deadline` between sibling iterations and bails
  early when exceeded. Default 2.0s, override with
  `defaults write app.menuet axWalkDeadline -float N`. Bounds the
  cumulative walk cost.

If the walk bails before producing any items, both panels show a
`NotRespondingView` ("{App} isn't responding right now. Try again in a
moment.") instead of an empty results area. Partial walks (some items
collected before bailing) display what was collected without an
indicator — the bimodal "complete or not responding" presentation is
intentional.

## Concurrency

`SWIFT_VERSION = 6.0` with `SWIFT_STRICT_CONCURRENCY = complete`. AX
calls require a single consistent thread (the project chose main) and
SwiftUI `@Published` mutations must be on main; both invariants are
compiler-enforced now via `@MainActor` on `MenuIndexProvider`,
`SearchSession`, `CheatsheetSession`, and `AppState`. AX wrapper types
themselves are not main-actor-isolated — they're synchronous and the
isolation flows through their callers.

## Trust prompt

`AppState.makeProcessTrusted` triggers the system Accessibility-
permissions prompt on first launch via `AXIsProcessTrustedWithOptions`.
Without it, AX queries return nothing.
