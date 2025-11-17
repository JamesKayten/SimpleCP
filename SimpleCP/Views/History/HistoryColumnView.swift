import SwiftUI

// Left column - recent clipboard history
struct HistoryColumnView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var clipboardService: ClipboardService?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack {
                Text("History")
                    .font(.headline)
                    .padding()

                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content
            if appState.isLoading && appState.historyItems.isEmpty {
                LoadingView(message: "Loading history...")
            } else if let error = appState.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await clipboardService?.refresh()
                    }
                }
            } else if appState.isSearching || appState.searchResults != nil {
                // Show search results
                searchResultsView
            } else {
                // Show regular history
                historyListView
            }
        }
        .onAppear {
            clipboardService = ClipboardService(apiClient: apiClient, appState: appState)
            Task {
                await clipboardService?.loadHistory()
                await clipboardService?.loadHistoryFolders()
            }
        }
    }

    // Search results view
    private var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let results = appState.searchResults {
                    if results.historyMatches.isEmpty {
                        Text("No history matches")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        Text("\(results.historyMatches.count) matches")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(results.historyMatches) { item in
                            HistoryItemView(item: item)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // Regular history list view
    private var historyListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Recent items (top 10)
                if !appState.historyItems.isEmpty {
                    Text("Recent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ForEach(Array(appState.historyItems.prefix(Constants.maxHistoryDisplay))) { item in
                        HistoryItemView(item: item)
                    }
                }

                // Auto-generated folders
                if !appState.historyFolders.isEmpty {
                    Divider()
                        .padding(.vertical, 8)

                    ForEach(appState.historyFolders) { folder in
                        HistoryFolderView(folder: folder)
                    }
                }

                if appState.historyItems.isEmpty && appState.historyFolders.isEmpty {
                    Text("No history items")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.vertical, 8)
        }
    }
}
