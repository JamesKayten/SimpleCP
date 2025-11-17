import SwiftUI

// Right column - snippet folders
struct SnippetsColumnView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @State private var snippetService: SnippetService?
    @State private var showingNewFolderDialog = false
    @State private var newFolderName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack {
                Text("Snippets")
                    .font(.headline)
                    .padding()

                Spacer()

                Button(action: {
                    showingNewFolderDialog = true
                }) {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.plain)
                .help("New Folder")
                .padding(.trailing)
            }
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content
            if appState.isLoading && appState.snippetFolders.isEmpty {
                LoadingView(message: "Loading snippets...")
            } else if let error = appState.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await snippetService?.refresh()
                    }
                }
            } else if appState.isSearching || appState.searchResults != nil {
                // Show search results
                searchResultsView
            } else {
                // Show snippet folders
                snippetFoldersView
            }
        }
        .sheet(isPresented: $showingNewFolderDialog) {
            newFolderDialog
        }
        .onAppear {
            snippetService = SnippetService(apiClient: apiClient, appState: appState)
            Task {
                await snippetService?.loadSnippets()
            }
        }
    }

    // Search results view
    private var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let results = appState.searchResults {
                    if results.snippetMatches.isEmpty {
                        Text("No snippet matches")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        Text("\(results.snippetMatches.count) matches")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(results.snippetMatches) { item in
                            SnippetItemView(item: item, folderName: item.folderPath ?? "Unknown")
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // Snippet folders view
    private var snippetFoldersView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if appState.snippetFolders.isEmpty {
                    Text("No snippet folders")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(appState.snippetFolders) { folder in
                        SnippetFolderView(folder: folder)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // New folder dialog
    private var newFolderDialog: some View {
        VStack(spacing: 16) {
            Text("Create New Folder")
                .font(.headline)

            TextField("Folder Name", text: $newFolderName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showingNewFolderDialog = false
                    newFolderName = ""
                }

                Button("Create") {
                    Task {
                        await snippetService?.createFolder(name: newFolderName)
                        showingNewFolderDialog = false
                        newFolderName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newFolderName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
