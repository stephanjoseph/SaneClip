import SwiftUI
import CloudKit

/// Settings view for iCloud sync configuration
struct SyncSettingsView: View {
    @State private var iCloudAvailable = false
    @State private var isSyncing = false
    @State private var lastSyncDate: Date?
    @State private var syncError: String?
    @State private var syncEnabled = UserDefaults.standard.bool(forKey: "syncEnabled")
    @State private var isCheckingStatus = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("iCloud Sync")
                    .font(.title2)
                    .fontWeight(.semibold)

                // Status Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: iCloudAvailable ? "checkmark.icloud" : "xmark.icloud")
                                .font(.title2)
                                .foregroundStyle(iCloudAvailable ? .green : .red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(iCloudAvailable ? "iCloud Available" : "iCloud Unavailable")
                                    .font(.headline)

                                if isCheckingStatus {
                                    Text("Checking status...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if !iCloudAvailable {
                                    Text("Sign in to iCloud in System Settings to enable sync")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if isCheckingStatus {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }

                        if iCloudAvailable {
                            Divider()

                            Toggle("Enable iCloud Sync", isOn: $syncEnabled)
                                .onChange(of: syncEnabled) { _, newValue in
                                    UserDefaults.standard.set(newValue, forKey: "syncEnabled")
                                    if newValue {
                                        setupSync()
                                    }
                                }

                            if syncEnabled {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Last Sync")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        if let date = lastSyncDate {
                                            Text(date, style: .relative)
                                                .font(.caption)
                                        } else {
                                            Text("Never")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Button {
                                        syncNow()
                                    } label: {
                                        if isSyncing {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                                        }
                                    }
                                    .disabled(isSyncing)
                                }
                            }
                        }
                    }
                    .padding(4)
                } label: {
                    Label("Status", systemImage: "icloud")
                }

                // Error Section
                if let error = syncError {
                    GroupBox {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                            Spacer()
                            Button("Dismiss") {
                                syncError = nil
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(4)
                    } label: {
                        Label("Error", systemImage: "exclamationmark.circle")
                    }
                }

                // Info Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        infoRow(
                            icon: "lock.shield",
                            title: "End-to-End Encrypted",
                            description: "All clipboard data is encrypted before leaving your device"
                        )

                        Divider()

                        infoRow(
                            icon: "macbook.and.iphone",
                            title: "Cross-Device Sync",
                            description: "Access your clipboard history across all your Macs"
                        )

                        Divider()

                        infoRow(
                            icon: "bolt",
                            title: "Real-Time Updates",
                            description: "Changes sync automatically in the background"
                        )
                    }
                    .padding(4)
                } label: {
                    Label("About iCloud Sync", systemImage: "info.circle")
                }

                // Setup Instructions (shown when iCloud not available)
                if !iCloudAvailable && !isCheckingStatus {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("To enable iCloud sync:")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            VStack(alignment: .leading, spacing: 8) {
                                instructionRow(number: 1, text: "Open System Settings")
                                instructionRow(number: 2, text: "Click your Apple ID at the top")
                                instructionRow(number: 3, text: "Click iCloud")
                                instructionRow(number: 4, text: "Make sure iCloud Drive is enabled")
                            }

                            Button("Open System Settings") {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane")!)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(4)
                    } label: {
                        Label("Setup Required", systemImage: "wrench.and.screwdriver")
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .task {
            await checkiCloudStatus()
        }
    }

    // MARK: - Helper Views

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(Color.blue.opacity(0.2))
                .clipShape(Circle())
            Text(text)
                .font(.caption)
        }
    }

    // MARK: - Actions

    private func checkiCloudStatus() async {
        isCheckingStatus = true
        defer { isCheckingStatus = false }

        iCloudAvailable = await CloudKitSyncService.shared.isAvailable()

        if iCloudAvailable && syncEnabled {
            // Get last sync date
            if let date = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
                lastSyncDate = date
            }
        }
    }

    private func setupSync() {
        Task {
            do {
                try await CloudKitSyncService.shared.setup()
            } catch {
                syncError = error.localizedDescription
            }
        }
    }

    private func syncNow() {
        isSyncing = true
        syncError = nil

        Task {
            do {
                let items = try await CloudKitSyncService.shared.fetchChanges()

                await MainActor.run {
                    lastSyncDate = Date()
                    UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
                    isSyncing = false

                    if !items.isEmpty {
                        // Notify about synced items
                        NotificationCenter.default.post(
                            name: .syncedItemsReceived,
                            object: nil,
                            userInfo: ["items": items]
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    syncError = error.localizedDescription
                    isSyncing = false
                }
            }
        }
    }
}

#Preview {
    SyncSettingsView()
        .frame(width: 500, height: 600)
}
