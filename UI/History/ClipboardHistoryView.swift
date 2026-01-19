import SwiftUI

struct ClipboardHistoryView: View {
    let clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isListFocused: Bool

    /// All navigable items (pinned + history)
    var allItems: [ClipboardItem] {
        filteredPinned + filteredHistory
    }

    var filteredHistory: [ClipboardItem] {
        let items = searchText.isEmpty ? clipboardManager.history : clipboardManager.history.filter { item in
            if case .text(let string) = item.content {
                return string.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
        // Filter out pinned items from main list (they show in pinned section)
        return items.filter { !clipboardManager.isPinned($0) }
    }

    var filteredPinned: [ClipboardItem] {
        guard searchText.isEmpty else {
            return clipboardManager.pinnedItems.filter { item in
                if case .text(let string) = item.content {
                    return string.localizedCaseInsensitiveContains(searchText)
                }
                return false
            }
        }
        return clipboardManager.pinnedItems
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search clipboard history...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.background.secondary)

            Divider()

            // History list
            if filteredHistory.isEmpty && filteredPinned.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Clipboard History" : "No Results",
                    systemImage: searchText.isEmpty ? "clipboard" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "Copy something to see it here" : "Try a different search")
                )
            } else {
                List {
                    // Pinned section
                    if !filteredPinned.isEmpty {
                        Section("Pinned") {
                            ForEach(Array(filteredPinned.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemRow(
                                    item: item,
                                    isPinned: true,
                                    clipboardManager: clipboardManager,
                                    isSelected: index == selectedIndex
                                )
                            }
                        }
                    }

                    // Recent section
                    Section(filteredPinned.isEmpty ? "" : "Recent") {
                        ForEach(Array(filteredHistory.enumerated()), id: \.element.id) { index, item in
                            let globalIndex = filteredPinned.count + index
                            ClipboardItemRow(
                                item: item,
                                isPinned: false,
                                clipboardManager: clipboardManager,
                                shortcutHint: index < 9 ? "⌘⌃\(index + 1)" : nil,
                                isSelected: globalIndex == selectedIndex
                            )
                        }
                    }
                }
                .listStyle(.plain)
                .focused($isListFocused)
                .onKeyPress(.downArrow) { moveSelection(by: 1); return .handled }
                .onKeyPress(.upArrow) { moveSelection(by: -1); return .handled }
                .onKeyPress(characters: CharacterSet(charactersIn: "jJ")) { _ in moveSelection(by: 1); return .handled }
                .onKeyPress(characters: CharacterSet(charactersIn: "kK")) { _ in moveSelection(by: -1); return .handled }
                .onKeyPress(.return) { pasteSelectedItem(); return .handled }
            }

            Divider()

            // Footer
            HStack {
                Text("\(clipboardManager.history.count) items")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.85))

                Spacer()

                Button(action: { SettingsWindowController.open() }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .help("Settings")

                Button("Clear All") {
                    clipboardManager.clearHistory()
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
            }
            .padding(8)
        }
        .onAppear {
            selectedIndex = 0
            isListFocused = true
        }
    }

    private func moveSelection(by offset: Int) {
        let itemCount = allItems.count
        guard itemCount > 0 else { return }
        selectedIndex = max(0, min(itemCount - 1, selectedIndex + offset))
    }

    private func pasteSelectedItem() {
        guard selectedIndex >= 0 && selectedIndex < allItems.count else { return }
        let item = allItems[selectedIndex]
        clipboardManager.paste(item: item)
    }
}
