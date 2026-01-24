import SwiftUI

/// History tab showing recent clipboard items
struct HistoryTab: View {
    @EnvironmentObject var viewModel: ClipboardHistoryViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.history.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        icon: "doc.on.clipboard",
                        title: "No Clips Yet",
                        message: "Copy something on your Mac and it will appear here."
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredHistory(searchText)) { item in
                            ClipboardItemCell(item: item)
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
                    .searchable(text: $searchText, prompt: "Search clips")
                }
            }
            .navigationTitle("History")
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
    HistoryTab()
        .environmentObject(ClipboardHistoryViewModel())
}
