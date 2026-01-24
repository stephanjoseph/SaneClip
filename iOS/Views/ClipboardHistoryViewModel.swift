import SwiftUI
import Combine
import UIKit

/// View model for iOS clipboard history viewer
@MainActor
class ClipboardHistoryViewModel: ObservableObject {
    @Published var history: [SharedClipboardItem] = []
    @Published var pinnedItems: [SharedClipboardItem] = []
    @Published var isLoading = false
    @Published var lastSyncTime: Date?
    @Published var errorMessage: String?

    private let userDefaults = UserDefaults(suiteName: "group.com.saneclip.app")

    init() {
        loadFromSharedContainer()
    }

    /// Load clipboard data from App Group shared container
    func loadFromSharedContainer() {
        guard let container = WidgetDataContainer.load() else {
            // No data yet - show empty state
            return
        }

        // Convert widget items to shared items for display
        history = container.recentItems.map { widgetItem in
            SharedClipboardItem(
                id: widgetItem.id,
                content: .text(widgetItem.preview),
                timestamp: widgetItem.timestamp,
                sourceAppName: widgetItem.sourceAppName,
                pasteCount: 0,
                deviceId: "",
                deviceName: ""
            )
        }

        pinnedItems = container.pinnedItems.map { widgetItem in
            SharedClipboardItem(
                id: widgetItem.id,
                content: .text(widgetItem.preview),
                timestamp: widgetItem.timestamp,
                sourceAppName: widgetItem.sourceAppName,
                pasteCount: 0,
                deviceId: "",
                deviceName: ""
            )
        }

        lastSyncTime = container.lastUpdated
    }

    /// Refresh data
    func refresh() async {
        isLoading = true
        errorMessage = nil

        // In a full implementation, this would fetch from CloudKit
        // For now, we just reload from the shared container
        loadFromSharedContainer()

        isLoading = false
    }

    /// Copy item to iOS clipboard
    func copyToClipboard(_ item: SharedClipboardItem) {
        switch item.content {
        case .text(let string):
            UIPasteboard.general.string = string
        case .imageData(let data, _, _):
            if let image = UIImage(data: data) {
                UIPasteboard.general.image = image
            }
        }
    }

    /// Filter history by search text
    func filteredHistory(_ searchText: String) -> [SharedClipboardItem] {
        guard !searchText.isEmpty else { return history }
        return history.filter { item in
            item.preview.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Filter pinned by search text
    func filteredPinned(_ searchText: String) -> [SharedClipboardItem] {
        guard !searchText.isEmpty else { return pinnedItems }
        return pinnedItems.filter { item in
            item.preview.localizedCaseInsensitiveContains(searchText)
        }
    }
}
