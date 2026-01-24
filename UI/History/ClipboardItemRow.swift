import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isPinned: Bool
    let clipboardManager: ClipboardManager
    var shortcutHint: String?
    var isSelected: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false
    @State private var showEditSheet = false
    @State private var editText = ""

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts: [String] = []

        // Content type and preview
        if case .image = item.content {
            parts.append("Image")
        } else if item.isURL {
            parts.append("Link: \(item.preview)")
        } else if item.isCode {
            parts.append("Code: \(item.preview)")
        } else {
            parts.append(item.preview)
        }

        // Pinned status
        if isPinned {
            parts.append("Pinned")
        }

        // Source app
        if let appName = item.sourceAppName {
            parts.append("from \(appName)")
        }

        // Paste count
        if item.pasteCount > 0 {
            parts.append("pasted \(item.pasteCount) time\(item.pasteCount == 1 ? "" : "s")")
        }

        return parts.joined(separator: ", ")
    }

    private var accentColor: Color {
        isPinned
            ? .pinnedOrange
            : .clipBlue
    }

    private var cardBackground: Color {
        // Hover and selection both use the same subtle highlight
        // Selection is distinguished by border, not fill
        if isHovering || isSelected {
            return colorScheme == .dark
                ? Color.white.opacity(0.12)
                : Color.black.opacity(0.06)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.03)
    }

    // Improved font selection: Monospaced for code
    private var itemFont: Font {
        item.isCode ? .system(.callout, design: .monospaced) : .system(.callout, weight: .medium)
    }

    // Content-type icon for faster visual scanning
    @ViewBuilder
    private var contentTypeIcon: some View {
        if case .image = item.content {
            Image(systemName: "photo")
        } else if item.isURL {
            Image(systemName: "link")
        } else if item.isCode {
            Image(systemName: "curlybraces")
        } else {
            Image(systemName: "text.alignleft")
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Accent bar on left (subtle, 65% opacity)
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor.opacity(0.65))
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
                    HStack(alignment: .top, spacing: 6) {
                        // Content-type icon for faster scanning
                        contentTypeIcon
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 14)

                        Text(item.preview)
                            .lineLimit(3)
                            .font(itemFont)
                            .foregroundStyle(.primary)
                    }

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
            .padding(.vertical, 12)
            .padding(.leading, 10)
            .padding(.trailing, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .opacity(isHovering || isSelected ? 1.0 : 0.7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accentColor.opacity(isSelected ? 0.4 : 0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            clipboardManager.paste(item: item)
        }
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .contextMenu {
            Button("Paste") { clipboardManager.paste(item: item) }
            Button("Paste as Plain Text") { clipboardManager.pasteAsPlainText(item: item) }

            // Text transform options (only for text content)
            if case .text = item.content {
                Menu("Paste As...") {
                    ForEach(TextTransform.allCases, id: \.self) { transform in
                        Button(transform.displayName) {
                            clipboardManager.pasteWithTransform(item: item, transform: transform)
                        }
                    }
                }
            }

            Divider()

            // Copy without paste
            Button("Copy") {
                clipboardManager.copyWithoutPaste(item: item)
            }

            // Share menu
            Button("Share...") {
                shareItem()
            }

            // Open Link (for URLs only)
            if item.isURL, case .text(let urlString) = item.content,
               let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                Button("Open Link") {
                    NSWorkspace.shared.open(url)
                }
            }

            // Edit (text only)
            if case .text(let text) = item.content {
                Button("Edit...") {
                    editText = text
                    showEditSheet = true
                }
            }

            Divider()
            Button("Add to Paste Stack") {
                clipboardManager.addToPasteStack(item)
            }
            Divider()
            Button(isPinned ? "Unpin" : "Pin") {
                clipboardManager.togglePin(item: item)
            }
            Divider()
            Button("Delete", role: .destructive) { clipboardManager.delete(item: item) }
        }
        .sheet(isPresented: $showEditSheet) {
            EditClipboardItemSheet(
                text: $editText,
                onSave: {
                    clipboardManager.updateItemContent(id: item.id, newContent: editText)
                    showEditSheet = false
                },
                onCancel: {
                    showEditSheet = false
                }
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to paste")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Share Helper

    private func shareItem() {
        var shareContent: Any?

        switch item.content {
        case .text(let string):
            shareContent = string
        case .image(let image):
            shareContent = image
        }

        guard let content = shareContent else { return }

        let picker = NSSharingServicePicker(items: [content])
        if let window = NSApp.keyWindow, let contentView = window.contentView {
            picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
        }
    }
}

// MARK: - Edit Clipboard Item Sheet

struct EditClipboardItemSheet: View {
    @Binding var text: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Clipboard Item")
                .font(.headline)

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 400, minHeight: 200)
                .border(Color.secondary.opacity(0.3), width: 1)

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(text.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 450, minHeight: 300)
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
