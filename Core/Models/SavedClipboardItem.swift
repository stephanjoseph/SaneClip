import Foundation

struct SavedClipboardItem: Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    let sourceAppBundleID: String?
    let sourceAppName: String?
    let pasteCount: Int

    init(
        id: UUID,
        text: String,
        timestamp: Date,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        pasteCount: Int = 0
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.pasteCount = pasteCount
    }

    // Custom decoder for backward compatibility with old history files
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        sourceAppBundleID = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleID)
        sourceAppName = try container.decodeIfPresent(String.self, forKey: .sourceAppName)
        pasteCount = try container.decodeIfPresent(Int.self, forKey: .pasteCount) ?? 0
    }
}
