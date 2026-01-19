import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isPinned: Bool
    let clipboardManager: ClipboardManager
    var shortcutHint: String? = nil
    var isSelected: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    private var accentColor: Color {
        isPinned
            ? .orange
            : Color(red: 0.0, green: 0.6, blue: 1.0)
    }

    private var cardBackground: Color {
        if isSelected {
            return colorScheme == .dark
                ? Color.accentColor.opacity(0.25)
                : Color.accentColor.opacity(0.15)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.03)
    }
    
    // Improved font selection: Monospaced for code
    private var itemFont: Font {
        item.isCode ? .system(.callout, design: .monospaced) : .system(.callout, weight: .medium)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Accent bar on left
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 3)

            HStack(alignment: .top, spacing: 8) {
                // Pin indicator
                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.top, 2)
                }

                // Content & metadata stacked
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.preview)
                        .lineLimit(3) // Increased from 2
                        .font(itemFont)
                        .foregroundStyle(.primary)

                    // Metadata line - fixed columns for alignment
                    HStack(spacing: 12) { // Increased spacing
                        // Source app icon
                        if let icon = item.sourceAppIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .help(item.sourceAppName ?? "Unknown app")
                        }

                        // Stats with icons
                        HStack(spacing: 4) {
                            if case .image = item.content {
                                Image(systemName: "photo")
                                    .font(.caption2)
                            }
                            Text(item.stats)
                                .font(.caption)
                        }
                        .foregroundStyle(.primary.opacity(0.7))

                        // Time ago
                        Text(item.timeAgo)
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.5))

                        // Paste count badge
                        if item.pasteCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 9))
                                Text("\(item.pasteCount)")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.green.opacity(0.8))
                            .help("Pasted \(item.pasteCount) time\(item.pasteCount == 1 ? "" : "s")")
                        }

                        Spacer()

                        if let hint = shortcutHint {
                            Text(hint)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.primary.opacity(0.55))
                                .padding(.horizontal, 4)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(4)
                        }
                    }
                    .lineLimit(1)
                }

                Spacer(minLength: 4)

            }
            .padding(.vertical, 10)
            .padding(.leading, 10)
            .padding(.trailing, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accentColor.opacity(isSelected ? 0.4 : 0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            clipboardManager.paste(item: item)
        }
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Paste") { clipboardManager.paste(item: item) }
            Button("Paste as Plain Text") { clipboardManager.pasteAsPlainText() }
            Divider()
            Button(isPinned ? "Unpin" : "Pin") {
                clipboardManager.togglePin(item: item)
            }
            Divider()
            Button("Delete", role: .destructive) { clipboardManager.delete(item: item) }
        }
    }
}

// MARK: - Paste Button Style with Dramatic Press Feedback

struct PasteButtonStyle: ButtonStyle {
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(
                Circle()
                    .fill(configuration.isPressed ? accentColor : accentColor.opacity(0.1))
            )
            .foregroundStyle(configuration.isPressed ? .white : accentColor)
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .shadow(color: configuration.isPressed ? accentColor.opacity(0.4) : .clear, radius: 4)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
