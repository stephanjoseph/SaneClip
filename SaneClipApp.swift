import SwiftUI
import AppKit
import KeyboardShortcuts
import os.log

private let appLogger = Logger(subsystem: "com.saneclip.app", category: "App")

// MARK: - Keyboard Shortcuts Extension

extension KeyboardShortcuts.Name {
    static let showClipboardHistory = Self("showClipboardHistory")
    static let pasteAsPlainText = Self("pasteAsPlainText")
}

// MARK: - AppDelegate

@MainActor
class SaneClipAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var clipboardManager: ClipboardManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        appLogger.info("SaneClip starting...")

        // Initialize clipboard manager
        clipboardManager = ClipboardManager()

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "SaneClip")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ClipboardHistoryView(clipboardManager: clipboardManager)
        )

        // Set up keyboard shortcuts
        setupKeyboardShortcuts()

        appLogger.info("SaneClip ready")
    }

    private func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .showClipboardHistory) { [weak self] in
            Task { @MainActor in
                self?.togglePopover()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .pasteAsPlainText) { [weak self] in
            Task { @MainActor in
                self?.clipboardManager.pasteAsPlainText()
            }
        }
    }

    @MainActor
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

// MARK: - Clipboard Manager

@MainActor
@Observable
class ClipboardManager {
    var history: [ClipboardItem] = []
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let maxHistorySize = 50
    private let logger = Logger(subsystem: "com.saneclip.app", category: "ClipboardManager")

    init() {
        lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
        loadHistory()
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Get clipboard content
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            addItem(ClipboardItem(content: .text(string)))
        } else if let image = NSImage(pasteboard: pasteboard) {
            addItem(ClipboardItem(content: .image(image)))
        }
    }

    private func addItem(_ item: ClipboardItem) {
        // Don't add duplicates at the top
        if let first = history.first, first.contentHash == item.contentHash {
            return
        }

        // Remove existing duplicate if present
        history.removeAll { $0.contentHash == item.contentHash }

        // Add to front
        history.insert(item, at: 0)

        // Trim to max size
        if history.count > maxHistorySize {
            history = Array(history.prefix(maxHistorySize))
        }

        saveHistory()
        logger.debug("Added clipboard item, history count: \(self.history.count)")
    }

    func paste(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let image):
            if let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        }

        // Move to front
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            let item = history.remove(at: index)
            history.insert(item, at: 0)
        }

        // Simulate Cmd+V
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            self.simulatePaste()
        }
    }

    func pasteAsPlainText() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            pasteboard.clearContents()
            pasteboard.setString(string, forType: .string)
            simulatePaste()
        }
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        keyDown?.flags = .maskCommand

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    func delete(item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    // MARK: - Persistence

    private var historyFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("SaneClip", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("history.json")
    }

    private func saveHistory() {
        // Only save text items (images are too large)
        let textItems = history.compactMap { item -> SavedClipboardItem? in
            if case .text(let string) = item.content {
                return SavedClipboardItem(id: item.id, text: string, timestamp: item.timestamp)
            }
            return nil
        }

        do {
            let data = try JSONEncoder().encode(textItems)
            try data.write(to: historyFileURL)
        } catch {
            logger.error("Failed to save history: \(error.localizedDescription)")
        }
    }

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyFileURL.path) else { return }

        do {
            let data = try Data(contentsOf: historyFileURL)
            let items = try JSONDecoder().decode([SavedClipboardItem].self, from: data)
            history = items.map { ClipboardItem(id: $0.id, content: .text($0.text), timestamp: $0.timestamp) }
        } catch {
            logger.error("Failed to load history: \(error.localizedDescription)")
        }
    }
}

// MARK: - Models

struct ClipboardItem: Identifiable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date

    init(id: UUID = UUID(), content: ClipboardContent, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }

    var contentHash: String {
        switch content {
        case .text(let string):
            return "text:\(string.hashValue)"
        case .image(let image):
            return "image:\(image.tiffRepresentation?.hashValue ?? 0)"
        }
    }

    var preview: String {
        switch content {
        case .text(let string):
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 100 {
                return String(trimmed.prefix(100)) + "..."
            }
            return trimmed
        case .image:
            return "[Image]"
        }
    }
}

enum ClipboardContent {
    case text(String)
    case image(NSImage)
}

struct SavedClipboardItem: Codable {
    let id: UUID
    let text: String
    let timestamp: Date
}

// MARK: - Clipboard History View

struct ClipboardHistoryView: View {
    let clipboardManager: ClipboardManager
    @State private var searchText = ""

    var filteredHistory: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.history
        }
        return clipboardManager.history.filter { item in
            if case .text(let string) = item.content {
                return string.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
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
            if filteredHistory.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Clipboard History" : "No Results",
                    systemImage: searchText.isEmpty ? "doc.on.clipboard" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "Copy something to see it here" : "Try a different search")
                )
            } else {
                List(filteredHistory) { item in
                    ClipboardItemRow(item: item) {
                        clipboardManager.paste(item: item)
                    } onDelete: {
                        clipboardManager.delete(item: item)
                    }
                }
                .listStyle(.plain)
            }

            Divider()

            // Footer
            HStack {
                Text("\(clipboardManager.history.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear All") {
                    clipboardManager.clearHistory()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(8)
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onPaste: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .lineLimit(2)
                    .font(.body)

                Text(item.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onPaste) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.plain)
            .help("Paste")
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onPaste()
        }
        .contextMenu {
            Button("Paste") { onPaste() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}
