import Foundation

/// Text transformations for clipboard content
enum TextTransform: String, CaseIterable {
    // Basic transforms
    case uppercase
    case lowercase
    case titleCase
    case trimWhitespace

    // Extended transforms (Phase 2)
    case reverseLines
    case jsonPrettyPrint
    case stripHTML
    case markdownToPlain

    var displayName: String {
        switch self {
        case .uppercase: return "UPPERCASE"
        case .lowercase: return "lowercase"
        case .titleCase: return "Title Case"
        case .trimWhitespace: return "Trimmed"
        case .reverseLines: return "Reverse Lines"
        case .jsonPrettyPrint: return "Format JSON"
        case .stripHTML: return "Strip HTML"
        case .markdownToPlain: return "Strip Markdown"
        }
    }

    func apply(to text: String) -> String {
        switch self {
        case .uppercase:
            return text.uppercased()
        case .lowercase:
            return text.lowercased()
        case .titleCase:
            return text.titleCased()
        case .trimWhitespace:
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .reverseLines:
            return text.components(separatedBy: "\n").reversed().joined(separator: "\n")
        case .jsonPrettyPrint:
            return text.prettyPrintedJSON()
        case .stripHTML:
            return text.strippedHTML()
        case .markdownToPlain:
            return text.strippedMarkdown()
        }
    }
}

extension String {
    /// Converts string to Title Case (first letter of each word capitalized)
    func titleCased() -> String {
        self.lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    /// Pretty prints JSON with indentation, returns original if invalid JSON
    func prettyPrintedJSON() -> String {
        guard let data = self.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                  withJSONObject: jsonObject,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return self  // Return original if not valid JSON
        }
        return prettyString
    }

    /// Strips HTML tags, keeping only text content
    func strippedHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            // Fallback: use regex to strip tags
            return self.replacingOccurrences(
                of: "<[^>]+>",
                with: "",
                options: .regularExpression
            )
        }
        return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strips markdown formatting, keeping plain text
    func strippedMarkdown() -> String {
        var result = self

        // Headers: # ## ### etc
        result = result.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)

        // Bold/italic: **text**, *text*, __text__, _text_
        result = result.replacingOccurrences(of: #"\*\*([^*]+)\*\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*([^*]+)\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"__([^_]+)__"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"_([^_]+)_"#, with: "$1", options: .regularExpression)

        // Strikethrough: ~~text~~
        result = result.replacingOccurrences(of: #"~~([^~]+)~~"#, with: "$1", options: .regularExpression)

        // Inline code: `code`
        result = result.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)

        // Links: [text](url)
        result = result.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)

        // Images: ![alt](url)
        result = result.replacingOccurrences(of: #"!\[([^\]]*)\]\([^)]+\)"#, with: "$1", options: .regularExpression)

        // Blockquotes: > text
        result = result.replacingOccurrences(of: #"^>\s+"#, with: "", options: .regularExpression)

        // Horizontal rules: --- or ***
        result = result.replacingOccurrences(of: #"^[-*]{3,}\s*$"#, with: "", options: .regularExpression)

        // List markers: - item or * item or 1. item
        result = result.replacingOccurrences(of: #"^[\s]*[-*+]\s+"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"^[\s]*\d+\.\s+"#, with: "", options: .regularExpression)

        return result
    }
}
