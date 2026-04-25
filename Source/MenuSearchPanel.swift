//
//  MenuSearchPanel.swift
//  MenuBar Pro
//
//  Created by Jesse Kasky on 7/23/23.
//  Copyright © 2023 Codjax. All rights reserved.
//

import SwiftUI


class MenuSearchPanel: NSPanel {

  init(contentRect: NSRect, view: () -> some View) {

    super.init(contentRect: contentRect,
               styleMask: [.nonactivatingPanel, .fullSizeContentView],
               backing: .buffered,
               defer: false)

    // Clear background, allow hosted view to draw entire background
    backgroundColor = NSColor.clear
    isOpaque = false

    // Allow moving panel by dragging on background
    isMovableByWindowBackground = true

    // Always move the panel to the active space (i.e. don't switch spaces)
    collectionBehavior = .moveToActiveSpace

    // Allow the panel to float on top of other windows
    isFloatingPanel = true
    level = .floating

    // Allow the pannel to be overlaid in a fullscreen space
    collectionBehavior.insert(.fullScreenAuxiliary)

    // Hide when unfocused
    hidesOnDeactivate = true

    // Animations appropriate for a utility window
    animationBehavior = .utilityWindow

    // Don't show a window title, even if it's set
    titleVisibility = .hidden
    titlebarAppearsTransparent = true

    // Hide all traffic light buttons
    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    // Ignore safe area, expand content view to entire panel.
    let hostingView = NSHostingView(rootView: view().ignoresSafeArea())
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    hostingView.sizingOptions = .standardBounds
    contentView = hostingView
  }

  // Allow panel to receive key events
  override var canBecomeKey: Bool {
    return true
  }

  // Allow panel to become apps main window
  override var canBecomeMain: Bool {
    return true
  }

  // On 'esc' close panel
  override func cancelOperation(_ sender: Any?) {
    close()
  }

  // When no longer main, close panel
  override func resignMain() {
    super.resignMain()
    close()
  }

  override func keyUp(with event: NSEvent) {
    let searchManager = SearchManager.shared
    if let key = event.characters?.unicodeScalars.first {
      switch Int(key.value) {
      case NSEvent.SpecialKey.downArrow.rawValue:
        searchManager.selectNext()
      case NSEvent.SpecialKey.upArrow.rawValue:
        searchManager.selectPrevious()
      case NSEvent.SpecialKey.carriageReturn.rawValue:
        if let item = searchManager.activeItem {
          dismissAndPerform(item.command)
        }
      default:
        break
      }
    }
    super.keyUp(with: event)
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    let searchManager = SearchManager.shared
    if let quickIndex = Int(event.charactersIgnoringModifiers!) {
      if quickIndex > 0 && quickIndex < 8 {
        let row = quickIndex - 1
        dismissAndPerform(searchManager.getResult(at: row).command)
        return true
      }
    }

    var characters = event.charactersIgnoringModifiers?.uppercased()
    if characters == nil || characters != "" {
      characters = event.characters?.uppercased()
    }

    if let itemWithEquivalent = searchManager.findMatchingResult({
      $0.command.character.uppercased() == characters?.uppercased() &&
      $0.command.modifiers == event.modifierFlags
    }) {
      dismissAndPerform(itemWithEquivalent.command)
    }
    return super.performKeyEquivalent(with:event)
  }

  private func dismissAndPerform(_ command: MenuItemCommand) {
    resignMain()
    // .activateAllWindows so AppKit restores the target's previously-key
    // window and its first responder.
    SearchManager.shared.currentApp?.activate(options: [.activateAllWindows])
    // NSMenu validation is lazy: items that depend on first-responder
    // context (Cut/Copy/etc.) can still be flagged disabled at the
    // moment of activation. Yield the runloop so the target processes
    // its activation event before we press.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      command.perform()
    }
  }
}
