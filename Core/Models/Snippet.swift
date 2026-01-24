import Foundation

/// A reusable text snippet with optional placeholders
struct Snippet: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var template: String       // Contains {{placeholders}}
    var shortcut: String?      // Optional keyboard trigger
    var category: String?
    let createdAt: Date
    var lastUsedAt: Date?
    var useCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        template: String,
        shortcut: String? = nil,
        category: String? = nil,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        useCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.template = template
        self.shortcut = shortcut
        self.category = category
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }
}
