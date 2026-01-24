import Foundation

/// Platform-agnostic clipboard content for cross-platform sync
enum SharedClipboardContent: Codable, Sendable {
    case text(String)
    case imageData(Data, width: Int, height: Int)

    private enum CodingKeys: String, CodingKey {
        case type, text, imageData, width, height
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "image":
            let data = try container.decode(Data.self, forKey: .imageData)
            let width = try container.decode(Int.self, forKey: .width)
            let height = try container.decode(Int.self, forKey: .height)
            self = .imageData(data, width: width, height: height)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown content type"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let string):
            try container.encode("text", forKey: .type)
            try container.encode(string, forKey: .text)
        case .imageData(let data, let width, let height):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .imageData)
            try container.encode(width, forKey: .width)
            try container.encode(height, forKey: .height)
        }
    }
}

/// Platform-agnostic clipboard item for cross-platform sync and iOS display
struct SharedClipboardItem: Identifiable, Codable, Sendable {
    let id: UUID
    let content: SharedClipboardContent
    let timestamp: Date
    let sourceAppBundleID: String?
    let sourceAppName: String?
    var pasteCount: Int
    let deviceId: String
    let deviceName: String

    init(
        id: UUID = UUID(),
        content: SharedClipboardContent,
        timestamp: Date = Date(),
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        pasteCount: Int = 0,
        deviceId: String = "",
        deviceName: String = ""
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.pasteCount = pasteCount
        self.deviceId = deviceId
        self.deviceName = deviceName
    }

    /// Text preview for display
    var preview: String {
        switch content {
        case .text(let string):
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            let singleLine = trimmed.replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )
            if singleLine.count > 100 {
                return String(singleLine.prefix(100)) + "..."
            }
            return singleLine
        case .imageData:
            return "[Image]"
        }
    }

    /// Check if content is a URL
    var isURL: Bool {
        guard case .text(let string) = content else { return false }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(string.startIndex..., in: string)
        let matches = detector?.numberOfMatches(in: string, options: [], range: range) ?? 0
        return matches > 0 && string.trimmingCharacters(in: .whitespacesAndNewlines).count < 500
    }

    /// Check if content looks like code
    var isCode: Bool {
        guard case .text(let string) = content else { return false }
        let codeIndicators = [
            "func ", "class ", "struct ", "enum ", "import ",
            "def ", "return ", "if ", "for ", "while ",
            "const ", "let ", "var ", "function ", "=>",
            "{", "}", "();", "[]", "</>", "#!/"
        ]
        return codeIndicators.contains { string.contains($0) }
    }

    /// Relative time for display
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
