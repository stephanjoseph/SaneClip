import SwiftUI

/// Settings tab for iOS app
struct SettingsTab: View {
    @EnvironmentObject var viewModel: ClipboardHistoryViewModel

    var body: some View {
        NavigationStack {
            List {
                // Sync Status Section
                Section {
                    HStack {
                        Label("Last Synced", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        if let lastSync = viewModel.lastSyncTime {
                            Text(lastSync, style: .relative)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Never")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        Task {
                            await viewModel.refresh()
                        }
                    } label: {
                        HStack {
                            Label("Sync Now", systemImage: "arrow.clockwise")
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                } header: {
                    Text("Sync")
                }

                // About Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://saneclip.com")!) {
                        Label("Website", systemImage: "globe")
                    }

                    Link(destination: URL(string: "https://saneclip.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                } header: {
                    Text("About")
                }

                // Info Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SaneClip iOS")
                            .font(.headline)
                        Text("View and copy your clipboard history synced from your Mac. Items copied here are added to your Mac's clipboard history.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("How It Works")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsTab()
        .environmentObject(ClipboardHistoryViewModel())
}
