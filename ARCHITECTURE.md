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

### 2. Menu indexing (`AXMenu.swift`, `AXMenuIndexer.swift`, `MenuItem.swift`, `MenuIndex.swift`, `Modifiers.swift`, `KeyGlyph.swift`, `FuzzyMatch.swift`)

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

### 3. UI (`App.swift`, `SearchPanel.swift`, `CheatsheetPanel.swift`, `SearchView.swift`, `CheatsheetView.swift`, `PanelChrome.swift`)

- `MenuBarExtra` for the status item.
- `SearchPanel` / `SearchView` — the search-and-invoke flow.
- `CheatsheetPanel` / `CheatsheetView` — the keyboard-shortcut
  reference grid (with live modifier-key filtering and incremental
  search).
- Both panels subclass `FloatingActionPanel` (defined in
  `PanelChrome.swift`), which configures them as `NSPanel`s with
  `.nonactivatingPanel + .floating + .moveToActiveSpace + .fullScreenAuxiliary`
  so they overlay the user's current space without disrupting it, and
  owns the shared dismissal flow (`dismiss()` → activate target;
  `dismissAndPerform(_:)` → dismiss + invoke).
- `PanelChrome.swift` also houses the shared SwiftUI chrome —
  `PanelBackground`, `ShortcutChip`, `NotRespondingView`,
  `NeedsAccessibilityView`, `fuzzyHighlight`.

State is split into three narrow `ObservableObject` types, each
`@MainActor`-isolated and singleton via `.shared`:

- `IndexProvider` — owns `currentApp` and `index`. The single source
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

`IndexProvider.shared.refresh()` must be called **before** the panel
takes key focus in `AppState.showSearchPanel` / `showCheatsheetPanel`.
Many apps disable selection-dependent menu items (Cut/Copy/etc.) when
their key window resigns key — if we walk after that point, those items
appear missing. The walk happens once per panel open; the sessions
query the cached index per keystroke.

## Critical invariant: dismiss → activate target → press when enabled

`FloatingActionPanel.dismissAndPerform` (inherited by both `SearchPanel`
and `CheatsheetPanel`) is the single path for invoking a result (Return,
⌘1–7, matched shortcut). It:
1. Close the panel (`resignMain()`).
2. Activate the target with `.activateAllWindows` so AppKit restores its
   previously-key window and first responder.
3. Hand off to `MenuItemCommand.performWhenReady`, which polls two
   readiness signals at 50ms intervals and presses the moment both
   report ready — falling through to press anyway after a 1s timeout:
   - `target.isActive` (the `NSRunningApplication`): step 2's
     activation is async and cross-process, so the AX press can land
     in the target before its previously-key window has been promoted
     back. Window-menu items that act on `NSApp.keyWindow` (e.g.
     "Move to ‹Display›") silently no-op if the press races the
     activation.
   - `delegate.isEnabled`: NSMenu validation is lazy, and
     first-responder-dependent items (Cut/Copy/etc.) stay disabled
     until the target's runloop has re-validated post-activation.
   Polling the actual signals is more reliable than a fixed defer,
   and each AX read is bounded by the system-wide messaging timeout
   so a hung target can't stall the loop.

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
- **Walk-level wall-clock deadline** — `IndexProvider.refresh`
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
compiler-enforced now via `@MainActor` on `IndexProvider`,
`SearchSession`, `CheatsheetSession`, and `AppState`. AX wrapper types
themselves are not main-actor-isolated — they're synchronous and the
isolation flows through their callers.

## Trust prompt

`AppState.makeProcessTrusted` triggers the system Accessibility-
permissions prompt on first launch via `AXIsProcessTrustedWithOptions`.
Without it, AX queries return nothing.
