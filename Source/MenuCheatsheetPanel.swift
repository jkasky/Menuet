import SwiftUI


class MenuCheatsheetPanel: NSPanel {

  init(contentRect: NSRect, view: () -> some View) {

    super.init(contentRect: contentRect,
               styleMask: [.nonactivatingPanel, .fullSizeContentView, .resizable],
               backing: .buffered,
               defer: false)

    backgroundColor = NSColor.clear
    isOpaque = false
    isMovableByWindowBackground = true
    collectionBehavior = .moveToActiveSpace
    isFloatingPanel = true
    level = .floating
    collectionBehavior.insert(.fullScreenAuxiliary)
    hidesOnDeactivate = true
    animationBehavior = .utilityWindow
    titleVisibility = .hidden
    titlebarAppearsTransparent = true

    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    let hostingView = NSHostingView(
      rootView: view()
        .environment(\.cheatsheetInvoke, CheatsheetInvokeAction { [weak self] command in
          self?.dismissAndPerform(command)
        })
        .environment(\.cheatsheetSize, CheatsheetSizeAction { [weak self] height in
          self?.applyIdealContentHeight(height)
        })
        .ignoresSafeArea()
    )
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    hostingView.sizingOptions = .standardBounds
    contentView = hostingView
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func cancelOperation(_ sender: Any?) {
    dismiss()
  }

  override func resignMain() {
    super.resignMain()
    close()
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if let item = SearchManager.shared.cheatsheetItem(matching: event) {
      dismissAndPerform(item.command)
      return true
    }
    return super.performKeyEquivalent(with: event)
  }

  private func dismiss() {
    resignMain()
    SearchManager.shared.currentApp?.activate(options: [.activateAllWindows])
  }

  func dismissAndPerform(_ command: MenuItemCommand) {
    dismiss()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      command.perform()
    }
  }

  static let topBuffer: CGFloat = 80
  static let minBottomBuffer: CGFloat = 60
  static let minHeight: CGFloat = 240

  func positionAtTop() {
    guard let visible = (screen ?? NSScreen.main)?.visibleFrame else { return }
    let width = frame.width
    let height = min(frame.height, visible.height - Self.topBuffer - Self.minBottomBuffer)
    let x = visible.minX + (visible.width - width) / 2
    let y = visible.maxY - Self.topBuffer - height
    setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
  }

  // SwiftUI reports the natural content (scrollable) height; we add it
  // to the chrome height and clamp against available screen space. The
  // resize is deferred so we don't re-enter AppKit layout while SwiftUI
  // is still propagating the preference value.
  func applyIdealContentHeight(_ contentHeight: CGFloat) {
    guard let visible = (screen ?? NSScreen.main)?.visibleFrame else { return }
    let chrome: CGFloat = 65 // header + divider + outer paddings
    let ideal = contentHeight + chrome
    let maxHeight = visible.height - Self.topBuffer - Self.minBottomBuffer
    let newHeight = min(max(ideal, Self.minHeight), maxHeight)
    if abs(newHeight - frame.height) < 0.5 { return }
    let x = frame.minX
    let y = visible.maxY - Self.topBuffer - newHeight
    let target = NSRect(x: x, y: y, width: frame.width, height: newHeight)
    DispatchQueue.main.async { [weak self] in
      self?.setFrame(target, display: true, animate: false)
    }
  }
}


struct CheatsheetInvokeAction {
  let perform: (MenuItemCommand) -> Void
}

private struct CheatsheetInvokeKey: EnvironmentKey {
  static let defaultValue = CheatsheetInvokeAction { _ in }
}

extension EnvironmentValues {
  var cheatsheetInvoke: CheatsheetInvokeAction {
    get { self[CheatsheetInvokeKey.self] }
    set { self[CheatsheetInvokeKey.self] = newValue }
  }
}


struct CheatsheetSizeAction {
  let report: (CGFloat) -> Void
}

private struct CheatsheetSizeKey: EnvironmentKey {
  static let defaultValue = CheatsheetSizeAction { _ in }
}

extension EnvironmentValues {
  var cheatsheetSize: CheatsheetSizeAction {
    get { self[CheatsheetSizeKey.self] }
    set { self[CheatsheetSizeKey.self] = newValue }
  }
}
