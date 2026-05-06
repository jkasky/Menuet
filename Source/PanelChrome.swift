import SwiftUI


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
  }
}


func fuzzyHighlight(_ title: String, query: String) -> AttributedString {
  guard !query.isEmpty else { return AttributedString(title) }
  let caseSensitive = UserDefaults.standard.searchCaseSensitive
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
