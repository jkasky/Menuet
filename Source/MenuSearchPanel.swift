//
//  MenuSearchPanel.swift
//  Menuet
//
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

  // On 'esc' close panel and restore focus to the previous app
  override func cancelOperation(_ sender: Any?) {
    dismiss()
  }

  // When no longer main, close panel
  override func resignMain() {
    super.resignMain()
    close()
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    var characters = event.charactersIgnoringModifiers?.uppercased()
    if characters == nil || characters != "" {
      characters = event.characters?.uppercased()
    }

    if let itemWithEquivalent = SearchSession.shared.findMatchingResult({
      $0.command.character.uppercased() == characters?.uppercased() &&
      $0.command.modifiers == event.modifierFlags
    }) {
      dismissAndPerform(itemWithEquivalent.command)
    }
    return super.performKeyEquivalent(with:event)
  }

  // Close the panel and restore the target app as frontmost.
  // .activateAllWindows so AppKit restores the target's previously-key
  // window and its first responder.
  private func dismiss() {
    resignMain()
    MenuIndexProvider.shared.currentApp?.activate(options: [.activateAllWindows])
  }

  func dismissAndPerform(_ command: MenuItemCommand) {
    dismiss()
    command.performWhenEnabled()
  }
}
