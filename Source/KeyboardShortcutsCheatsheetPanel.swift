import SwiftUI

class KeyboardShortcutsCheatsheetPanel: NSPanel {

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

        // Allow the panel to be overlaid in a fullscreen space
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
}

struct CheatsheetView: View {
    @EnvironmentObject var searchManager: SearchManager

    var body: some View {
        VStack {
            SearchBar()
            CheatsheetGrid()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
}

struct SearchBar: View {
    @EnvironmentObject var searchManager: SearchManager

    var body: some View {
        TextField("Search Shortcuts", text: $searchManager.query)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .onReceive(
                searchManager.$query.debounce(for: .seconds(0.4), scheduler: DispatchQueue.main)
            ) { q in
                searchManager.search(q)
            }
    }
}

struct CheatsheetGrid: View {
    @EnvironmentObject var searchManager: SearchManager

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                ForEach(searchManager.searchResults, id: \.id) { item in
                    ShortcutItemView(item: item)
                }
            }
        }
    }
}

struct ShortcutItemView: View {
    var item: MenuItem

    var body: some View {
        VStack {
            Text(item.command.stringValue)
                .font(.headline)
            Text(item.title)
                .font(.subheadline)
            Text(item.pathDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}
