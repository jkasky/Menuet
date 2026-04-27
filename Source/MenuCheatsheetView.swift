import SwiftUI


struct MenuCheatsheetView: View {
  @EnvironmentObject var searchManager: SearchManager
  @Environment(\.cheatsheetSize) private var sizeAction

  private static let scrollTopID = "cheatsheet.top"

  var body: some View {
    ZStack {
      VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 0) {
        CheatsheetHeader(
          appIcon: searchManager.currentApp?.icon,
          appName: searchManager.currentApp?.localizedName ?? "Keyboard Shortcuts",
          query: searchManager.cheatsheetQuery
        )
          .padding(.horizontal, 20)
          .padding(.top, 16)
          .padding(.bottom, 12)

        Divider().opacity(0.4)

        GeometryReader { geo in
          ScrollViewReader { proxy in
            ScrollView {
              Color.clear.frame(height: 0).id(Self.scrollTopID)
              MasonryColumns(
                groups: searchManager.cheatsheetGroups,
                availableWidth: geo.size.width - 40
              )
              .padding(20)
              .background(
                GeometryReader { inner in
                  Color.clear.preference(
                    key: ContentHeightKey.self,
                    value: inner.size.height
                  )
                }
              )
            }
            .onChange(of: searchManager.cheatsheetResetTrigger) { _, _ in
              proxy.scrollTo(Self.scrollTopID, anchor: .top)
            }
            .onChange(of: searchManager.cheatsheetActiveItem?.id) { _, newID in
              guard let id = newID else { return }
              withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo(id, anchor: .center)
              }
            }
            .onPreferenceChange(ContentHeightKey.self) { height in
              sizeAction.report(height)
            }
          }
        }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
    )
  }
}


private struct CheatsheetHeader: View {
  let appIcon: NSImage?
  let appName: String
  let query: String

  var body: some View {
    HStack(spacing: 10) {
      if query.isEmpty, let icon = appIcon {
        Image(nsImage: icon)
          .resizable()
          .interpolation(.high)
          .frame(width: 22, height: 22)
      } else {
        Image(systemName: query.isEmpty ? "keyboard" : "magnifyingglass")
          .foregroundStyle(query.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.accentColor))
          .frame(width: 22, height: 22)
      }
      if query.isEmpty {
        Text("Keyboard Shortcuts")
          .font(.system(.headline, design: .rounded))
      } else {
        Text(query)
          .font(.system(.headline, design: .rounded))
          .foregroundStyle(Color.accentColor)
          .lineLimit(1)
      }
      Spacer()
      Text(appName)
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(.secondary)
    }
  }
}


private struct ContentHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}


private struct MasonryColumns: View {
  let groups: [CheatsheetGroup]
  let availableWidth: CGFloat

  private static let minColumnWidth: CGFloat = 260
  private static let columnSpacing: CGFloat = 24
  private static let sectionSpacing: CGFloat = 20

  var body: some View {
    let columns = distribute(into: columnCount)
    HStack(alignment: .top, spacing: Self.columnSpacing) {
      ForEach(columns.indices, id: \.self) { i in
        VStack(alignment: .leading, spacing: Self.sectionSpacing) {
          ForEach(columns[i]) { group in
            CheatsheetSection(group: group)
          }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
      }
    }
  }

  private var columnCount: Int {
    let usable = max(availableWidth, Self.minColumnWidth)
    let n = Int((usable + Self.columnSpacing) / (Self.minColumnWidth + Self.columnSpacing))
    return max(1, min(n, max(1, groups.count)))
  }

  // Greedy bin-pack by row count so columns balance in height.
  private func distribute(into n: Int) -> [[CheatsheetGroup]] {
    var columns: [[CheatsheetGroup]] = Array(repeating: [], count: n)
    var weights = Array(repeating: 0, count: n)
    for group in groups {
      let target = weights.enumerated().min { $0.element < $1.element }?.offset ?? 0
      columns[target].append(group)
      // +2 accounts for header + divider chrome per section.
      weights[target] += group.items.count + 2
    }
    return columns
  }
}


private struct CheatsheetSection: View {
  let group: CheatsheetGroup

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(group.menu)
        .font(.system(.subheadline, design: .rounded).weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .padding(.bottom, 2)

      Divider().opacity(0.5)

      VStack(alignment: .leading, spacing: 2) {
        ForEach(group.items) { item in
          ShortcutRow(item: item)
        }
      }
      .padding(.top, 4)
    }
  }
}


private struct ShortcutRow: View {
  let item: MenuItem

  @EnvironmentObject var searchManager: SearchManager
  @Environment(\.cheatsheetInvoke) private var invoke
  @State private var hovering = false

  var body: some View {
    let query = searchManager.cheatsheetQuery
    let isActive = searchManager.cheatsheetActiveItem?.id == item.id
    let isMatch = query.isEmpty || searchManager.cheatsheetMatchIDs.contains(item.id)
    let dimmed = !query.isEmpty && !isMatch

    Button {
      invoke.perform(item.command)
    } label: {
      HStack(alignment: .center, spacing: 10) {
        ShortcutChip(text: item.command.stringValue)
        VStack(alignment: .leading, spacing: 1) {
          Text(item.title)
            .font(.system(.body))
            .foregroundStyle(isActive ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
            .lineLimit(1)
            .truncationMode(.tail)
          if item.path.count > 2 {
            Text(submenuBreadcrumb)
              .font(.caption2)
              .foregroundStyle(isActive ? AnyShapeStyle(Color.white.opacity(0.85)) : AnyShapeStyle(.tertiary))
              .lineLimit(1)
          }
        }
        Spacer(minLength: 0)
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 6)
      .padding(.vertical, 4)
      .background(
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .fill(rowBackground)
      )
    }
    .buttonStyle(.plain)
    .onHover { hovering = $0 }
    .opacity(dimmed ? 0.35 : 1.0)
    .id(item.id)
  }

  private var rowBackground: Color {
    let isActive = searchManager.cheatsheetActiveItem?.id == item.id
    if isActive { return Color.accentColor }
    if hovering { return Color.primary.opacity(0.08) }
    return Color.clear
  }

  private var submenuBreadcrumb: String {
    item.path.dropFirst().dropLast().joined(separator: " › ")
  }
}


private struct ShortcutChip: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.system(.body, design: .rounded).weight(.medium))
      .foregroundStyle(.primary)
      .frame(minWidth: 56, alignment: .trailing)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(
        RoundedRectangle(cornerRadius: 5, style: .continuous)
          .fill(Color.primary.opacity(0.08))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 5, style: .continuous)
          .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
      )
  }
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
