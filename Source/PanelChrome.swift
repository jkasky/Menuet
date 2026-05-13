import SwiftUI


/// Base class for the search and cheatsheet floating panels. Owns the
/// common NSPanel chrome (clear background, floating level, hides on
/// deactivate, traffic-light hidden, fullscreen-auxiliary), the focus
/// behavior (`canBecomeKey/Main = true`), and the dismissal flow
/// (`resignMain → close`, `dismiss → activate target`,
/// `dismissAndPerform → dismiss + invoke`).
///
/// Subclasses pass any extra `styleMask` bits and install their own
/// content view; they may override `cancelOperation` for behavior
/// beyond the default dismiss (the cheatsheet uses this to clear its
/// query before falling back to closing the panel).
class FloatingActionPanel: NSPanel {

  private let menus: IndexProvider

  init(contentRect: NSRect, menus: IndexProvider, styleMask extra: NSWindow.StyleMask = []) {
    self.menus = menus
    super.init(
      contentRect: contentRect,
      styleMask: extra.union([.nonactivatingPanel, .fullSizeContentView]),
      backing: .buffered,
      defer: false)

    backgroundColor = .clear
    isOpaque = false
    isMovableByWindowBackground = true
    collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    isFloatingPanel = true
    level = .floating
    hidesOnDeactivate = true
    animationBehavior = .utilityWindow
    titleVisibility = .hidden
    titlebarAppearsTransparent = true

    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func resignMain() {
    super.resignMain()
    close()
  }

  override func cancelOperation(_ sender: Any?) {
    dismiss()
  }

  /// Close the panel and restore the previous frontmost app.
  /// `.activateAllWindows` lets AppKit restore the target's
  /// previously-key window and its first responder.
  func dismiss() {
    resignMain()
    menus.currentApp?.activate(options: [.activateAllWindows])
  }

  func dismissAndPerform(_ command: MenuItemCommand) {
    dismiss()
    command.performWhenEnabled()
  }
}


struct PanelBackground<Content: View>: View {
  private let cornerRadius: CGFloat
  private let content: Content

  init(cornerRadius: CGFloat = 14, @ViewBuilder content: () -> Content) {
    self.cornerRadius = cornerRadius
    self.content = content()
  }

  var body: some View {
    ZStack {
      VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        .ignoresSafeArea()
      content
    }
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
    )
  }
}


struct NotRespondingView: View {
  let appName: String

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 28))
        .foregroundStyle(.secondary)
      Text("\(appName) isn't responding right now.")
        .font(.system(.body, design: .rounded))
        .foregroundStyle(.primary)
      Text("Try again in a moment.")
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(.secondary)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(24)
  }
}


struct NeedsAccessibilityView: View {
  // Legacy URL still resolves on Sonoma/Sequoia and avoids the macOS-13+
  // pane-id rename. NSWorkspace.open silently no-ops if the URL is
  // unparseable, so a stale URL degrades to "button does nothing"
  // rather than crashing.
  private static let settingsURL = URL(
    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "lock.shield")
        .font(.system(size: 28))
        .foregroundStyle(.secondary)
      Text("Menuet needs Accessibility permission")
        .font(.system(.body, design: .rounded))
        .foregroundStyle(.primary)
      Text("Menuet reads the menus of the frontmost app using macOS Accessibility. Without permission, it can't return any results.")
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      Button("Open System Settings") {
        if let url = Self.settingsURL {
          NSWorkspace.shared.open(url)
        }
      }
      .buttonStyle(.borderedProminent)
      .padding(.top, 4)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(24)
  }
}


struct ShortcutChip: View {
  let text: String
  var minWidth: CGFloat = 56
  var highlighted: Bool = false

  var body: some View {
    Text(text)
      .font(.system(.body, design: .rounded).weight(.medium))
      .foregroundStyle(.primary)
      .frame(minWidth: minWidth, alignment: .trailing)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(
        RoundedRectangle(cornerRadius: 5, style: .continuous)
          .fill(highlighted ? Color.white.opacity(0.22) : Color.primary.opacity(0.08))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 5, style: .continuous)
          .strokeBorder(
            highlighted ? Color.white.opacity(0.4) : Color.primary.opacity(0.10),
            lineWidth: highlighted ? 1 : 0.5
          )
      )
      .accessibilityHidden(true)
  }
}


func fuzzyHighlight(_ title: String, query: String) -> AttributedString {
  guard !query.isEmpty else { return AttributedString(title) }
  let caseSensitive = UserDefaults.standard.searchMatchCase
  guard let match = FuzzyMatch.score(
    query: query, candidate: title, caseSensitive: caseSensitive
  ) else {
    return AttributedString(title)
  }
  let matched = Set(match.matchedIndices)
  var attr = AttributedString()
  for (i, ch) in title.enumerated() {
    var piece = AttributedString(String(ch))
    if matched.contains(i) {
      piece.underlineStyle = .single
    }
    attr += piece
  }
  return attr
}


struct VisualEffectView: NSViewRepresentable {
  let material: NSVisualEffectView.Material
  let blendingMode: NSVisualEffectView.BlendingMode

  func makeNSView(context: Context) -> NSVisualEffectView {
    let v = NSVisualEffectView()
    v.material = material
    v.blendingMode = blendingMode
    v.state = .active
    v.isEmphasized = true
    return v
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
  }
}
