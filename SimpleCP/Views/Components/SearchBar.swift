import SwiftUI

// Always-visible search bar
struct SearchBar: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var searchService: SearchService?

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search clipboard...", text: $appState.searchQuery)
                .textFieldStyle(.plain)
                .onChange(of: appState.searchQuery) { _, newValue in
                    Task {
                        if let service = searchService {
                            await service.search(query: newValue)
                        }
                    }
                }

            if !appState.searchQuery.isEmpty {
                Button(action: {
                    appState.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if appState.isSearching {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            searchService = SearchService(apiClient: apiClient, appState: appState)
        }
    }
}
