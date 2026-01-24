import Testing
@testable import SaneClip

struct SaneClipTests {
    @Test("ClipboardItem preview truncates long text")
    func clipboardItemPreviewTruncation() {
        let longText = String(repeating: "a", count: 200)
        let item = ClipboardItem(content: .text(longText))

        #expect(item.preview.count == 103) // 100 chars + "..."
        #expect(item.preview.hasSuffix("..."))
    }

    @Test("ClipboardItem preview returns full short text")
    func clipboardItemPreviewShortText() {
        let shortText = "Hello, World!"
        let item = ClipboardItem(content: .text(shortText))

        #expect(item.preview == shortText)
    }

    @Test("ClipboardItem content hash is consistent")
    func clipboardItemContentHash() {
        let text = "Test content"
        let item1 = ClipboardItem(content: .text(text))
        let item2 = ClipboardItem(content: .text(text))

        #expect(item1.contentHash == item2.contentHash)
    }

    @Test("ClipboardItem stores source app info")
    func clipboardItemSourceApp() {
        let item = ClipboardItem(
            content: .text("Test"),
            sourceAppBundleID: "com.apple.Safari",
            sourceAppName: "Safari"
        )

        #expect(item.sourceAppBundleID == "com.apple.Safari")
        #expect(item.sourceAppName == "Safari")
    }

    @Test("ClipboardItem source app info is optional")
    func clipboardItemSourceAppOptional() {
        let item = ClipboardItem(content: .text("Test"))

        #expect(item.sourceAppBundleID == nil)
        #expect(item.sourceAppName == nil)
    }

    @Test("SettingsModel excludes apps correctly")
    @MainActor
    func settingsModelExcludedApps() {
        let settings = SettingsModel.shared

        // Save original state
        let originalExcluded = settings.excludedApps

        // Test excluding an app
        settings.excludedApps = ["com.test.app"]
        #expect(settings.isAppExcluded("com.test.app") == true)
        #expect(settings.isAppExcluded("com.other.app") == false)
        #expect(settings.isAppExcluded(nil) == false)

        // Restore original state
        settings.excludedApps = originalExcluded
    }

    @Test("URL tracking parameters are stripped")
    func urlTrackingParamsStripped() {
        let urlWithTracking = "https://example.com/page?" +
            "utm_source=newsletter&utm_medium=email&real_param=keep&fbclid=abc123"
        let cleaned = ClipboardItem.stripTrackingParams(from: urlWithTracking)

        #expect(cleaned == "https://example.com/page?real_param=keep")
        #expect(!cleaned.contains("utm_"))
        #expect(!cleaned.contains("fbclid"))
    }

    @Test("Clean URL remains unchanged")
    func cleanUrlUnchanged() {
        let cleanUrl = "https://example.com/page?id=123&name=test"
        let result = ClipboardItem.stripTrackingParams(from: cleanUrl)

        #expect(result == cleanUrl)
    }

    // MARK: - Extended Text Transforms (Phase 2)

    @Test("Reverse lines reverses multi-line text")
    func testReverseLines() {
        let input = "Line 1\nLine 2\nLine 3"
        let result = TextTransform.reverseLines.apply(to: input)

        #expect(result == "Line 3\nLine 2\nLine 1")
    }

    @Test("JSON pretty print formats valid JSON")
    func testJsonPrettyPrint() {
        let input = #"{"name":"John","age":30}"#
        let result = TextTransform.jsonPrettyPrint.apply(to: input)

        #expect(result.contains("  "))  // Has indentation
        #expect(result.contains("\n"))  // Has newlines
        #expect(result.contains("\"name\""))
    }

    @Test("JSON pretty print returns original for invalid JSON")
    func testJsonPrettyPrintInvalid() {
        let input = "not valid json { broken"
        let result = TextTransform.jsonPrettyPrint.apply(to: input)

        #expect(result == input)  // Returns original unchanged
    }

    @Test("Strip HTML removes tags and keeps text")
    func testStripHTML() {
        let input = "<p>Hello <strong>world</strong>!</p>"
        let result = TextTransform.stripHTML.apply(to: input)

        #expect(!result.contains("<"))
        #expect(!result.contains(">"))
        #expect(result.contains("Hello"))
        #expect(result.contains("world"))
    }

    @Test("Strip Markdown removes formatting")
    func testMarkdownToPlain() {
        let input = "# Header\n**bold** and *italic* text"
        let result = TextTransform.markdownToPlain.apply(to: input)

        #expect(!result.contains("#"))
        #expect(!result.contains("**"))
        #expect(!result.contains("*"))
        #expect(result.contains("bold"))
        #expect(result.contains("italic"))
    }

    @Test("Strip Markdown handles links")
    func testMarkdownLinksStripped() {
        let input = "Check out [this link](https://example.com) for more info"
        let result = TextTransform.markdownToPlain.apply(to: input)

        #expect(!result.contains("["))
        #expect(!result.contains("]("))
        #expect(result.contains("this link"))
    }

    // MARK: - Clipboard Rules Engine Tests (Phase 2)

    @Test("ClipboardRulesManager normalizes line endings")
    @MainActor
    func testNormalizeLineEndings() {
        let rules = ClipboardRulesManager.shared

        // Save original state
        let originalValue = rules.normalizeLineEndings

        // Enable rule
        rules.normalizeLineEndings = true

        // Disable other rules to isolate test
        let originalTrim = rules.autoTrimWhitespace
        let originalSpaces = rules.removeDuplicateSpaces
        let originalLowercase = rules.lowercaseURLs
        let originalTracking = rules.stripTrackingParams

        rules.autoTrimWhitespace = false
        rules.removeDuplicateSpaces = false
        rules.lowercaseURLs = false
        rules.stripTrackingParams = false

        let input = "Line 1\r\nLine 2\rLine 3\nLine 4"
        let result = rules.process(input)

        #expect(!result.contains("\r"))
        #expect(result == "Line 1\nLine 2\nLine 3\nLine 4")

        // Restore original state
        rules.normalizeLineEndings = originalValue
        rules.autoTrimWhitespace = originalTrim
        rules.removeDuplicateSpaces = originalSpaces
        rules.lowercaseURLs = originalLowercase
        rules.stripTrackingParams = originalTracking
    }

    @Test("ClipboardRulesManager removes duplicate spaces")
    @MainActor
    func testRemoveDuplicateSpaces() {
        let rules = ClipboardRulesManager.shared

        // Save original state
        let originalSpaces = rules.removeDuplicateSpaces
        let originalTrim = rules.autoTrimWhitespace
        let originalTracking = rules.stripTrackingParams
        let originalLineEndings = rules.normalizeLineEndings
        let originalLowercase = rules.lowercaseURLs

        // Configure for isolated test
        rules.removeDuplicateSpaces = true
        rules.autoTrimWhitespace = false
        rules.stripTrackingParams = false
        rules.normalizeLineEndings = false
        rules.lowercaseURLs = false

        let input = "Hello    world  test"
        let result = rules.process(input)

        #expect(result == "Hello world test")

        // Restore
        rules.removeDuplicateSpaces = originalSpaces
        rules.autoTrimWhitespace = originalTrim
        rules.stripTrackingParams = originalTracking
        rules.normalizeLineEndings = originalLineEndings
        rules.lowercaseURLs = originalLowercase
    }
}
