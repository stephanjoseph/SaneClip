import SwiftUI

/// Pinned tab showing pinned clipboard items
struct PinnedTab: View {
    @EnvironmentObject var viewModel: ClipboardHistoryViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.pinnedItems.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        icon: "pin.slash",
                        title: "No Pinned Clips",
                        message: "Pin items on your Mac to access them quickly here."
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredPinned(searchText)) { item in
                            ClipboardItemCell(item: item, showPin: true)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        viewModel.copyToClipboard(item)
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search pinned")
                }
            }
            .navigationTitle("Pinned")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

#Preview {
    PinnedTab()
        .environmentObject(ClipboardHistoryViewModel())
}
