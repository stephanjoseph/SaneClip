import SwiftUI

/// Cell for displaying a clipboard item in a list
struct ClipboardItemCell: View {
    let item: SharedClipboardItem
    var showPin: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Content type icon
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                // Preview text
                Text(item.preview)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // Metadata row
                HStack(spacing: 8) {
                    // Timestamp
                    Text(item.relativeTime)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    // Source app
                    if let source = item.sourceAppName {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(source)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Pin indicator
                    if showPin {
                        Spacer()
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var iconName: String {
        switch item.content {
        case .text:
            if item.isURL { return "link" }
            if item.isCode { return "chevron.left.forwardslash.chevron.right" }
            return "doc.text"
        case .imageData:
            return "photo"
        }
    }

    private var iconColor: Color {
        switch item.content {
        case .text:
            if item.isURL { return .blue }
            if item.isCode { return .orange }
            return .primary
        case .imageData:
            return .purple
        }
    }
}

#Preview {
    List {
        ClipboardItemCell(
            item: SharedClipboardItem(
                content: .text("Sample clipboard text that might be a bit longer"),
                sourceAppName: "Safari"
            )
        )
        ClipboardItemCell(
            item: SharedClipboardItem(
                content: .text("https://example.com/page"),
                sourceAppName: "Chrome"
            )
        )
        ClipboardItemCell(
            item: SharedClipboardItem(
                content: .text("func hello() { print(\"Hi\") }"),
                sourceAppName: "Xcode"
            ),
            showPin: true
        )
    }
}
