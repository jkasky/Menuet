import SwiftUI


struct MenuCheatsheetView: View {
  @EnvironmentObject var cheatsheet: CheatsheetSession
  @EnvironmentObject var menus: MenuIndexProvider
  @Environment(\.cheatsheetSize) private var sizeAction

  private static let scrollTopID = "cheatsheet.top"

  var body: some View {
    PanelBackground {
      VStack(alignment: .leading, spacing: 0) {
        CheatsheetHeader(
          appIcon: menus.currentApp?.icon,
          appName: menus.currentApp?.localizedName ?? "Keyboard Shortcuts",
          query: cheatsheet.query,
          matchCount: cheatsheet.matchIDs.count,
          modifierFilter: cheatsheet.modifierFilter
        )
          .padding(.horizontal, 16)
          .padding(.vertical, 8)

        Divider().opacity(0.4)

        GeometryReader { geo in
          ScrollViewReader { proxy in
            ScrollView {
              Color.clear.frame(height: 0).id(Self.scrollTopID)
              MasonryColumns(
                groups: cheatsheet.filteredGroups,
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
            .onChange(of: cheatsheet.resetTrigger) { _, _ in
              proxy.scrollTo(Self.scrollTopID, anchor: .top)
            }
            .onChange(of: cheatsheet.activeItem?.id) { _, newID in
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
  }
}


private struct CheatsheetHeader: View {
  let appIcon: NSImage?
  let appName: String
  let query: String
  let matchCount: Int
  let modifierFilter: NSEvent.ModifierFlags

  var body: some View {
    ZStack {
      HStack(spacing: 10) {
        if query.isEmpty, let icon = appIcon {
          Image(nsImage: icon)
            .resizable()
            .interpolation(.high)
            .frame(width: 48, height: 48)
        } else {
          Image(systemName: query.isEmpty ? "keyboard" : "magnifyingglass")
            .font(.system(size: 28))
            .foregroundStyle(query.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.accentColor))
            .frame(width: 48, height: 48)
        }
        if query.isEmpty {
          Text("Keyboard Shortcuts")
            .font(.system(.headline, design: .rounded))
        } else {
          Text(query)
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Color.accentColor)
            .lineLimit(1)
          Text("\(matchCount) \(matchCount == 1 ? "match" : "matches")")
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        Spacer()
        Text(appName)
          .font(.system(.subheadline, design: .rounded))
          .foregroundStyle(.secondary)
      }
      if !modifierFilter.isEmpty {
        ModifierIndicatorChips(flags: modifierFilter)
      }
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

  @EnvironmentObject var cheatsheet: CheatsheetSession
  @Environment(\.cheatsheetInvoke) private var invoke
  @State private var hovering = false

  var body: some View {
    let query = cheatsheet.query
    let isActive = cheatsheet.activeItem?.id == item.id
    let isMatch = query.isEmpty || cheatsheet.matchIDs.contains(item.id)
    let dimmed = !query.isEmpty && !isMatch

    Button {
      invoke.perform(item.command)
    } label: {
      HStack(alignment: .center, spacing: 10) {
        ShortcutChip(text: item.command.stringValue)
        VStack(alignment: .leading, spacing: 1) {
          Text(fuzzyHighlight(item.title, query: query))
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
    let isActive = cheatsheet.activeItem?.id == item.id
    if isActive { return Color.accentColor }
    if hovering { return Color.primary.opacity(0.08) }
    return Color.clear
  }

  private var submenuBreadcrumb: String {
    item.path.dropFirst().dropLast().joined(separator: " › ")
  }
}


private struct ModifierIndicatorChips: View {
  let flags: NSEvent.ModifierFlags

  private static let chipTable: [(flag: NSEvent.ModifierFlags, symbol: String, color: Color, label: String)] = [
    (.control,  KeyGlyph.Control.characters, .yellow,    "Control"),
    (.option,   KeyGlyph.Option.characters,  .yellow,    "Option"),
    (.shift,    KeyGlyph.Shift.characters,   .blue,      "Shift"),
    (.command,  KeyGlyph.Command.characters, .blue,      "Command"),
    (.function, KeyGlyph.Globe.characters,   .secondary, "Function"),
  ]

  var body: some View {
    HStack(spacing: 4) {
      ForEach(Self.chipTable.filter { flags.contains($0.flag) }, id: \.label) { entry in
        chip(symbol: entry.symbol, color: entry.color, label: entry.label)
      }
    }
  }

  @ViewBuilder
  private func chip(symbol: String, color: Color, label: String) -> some View {
    HStack(spacing: 2) {
      Text(symbol).foregroundStyle(color)
      Text(label).foregroundStyle(.secondary)
    }
    .font(.system(.caption2, design: .monospaced))
    .padding(.horizontal, 5)
    .padding(.vertical, 2)
    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
  }
}

