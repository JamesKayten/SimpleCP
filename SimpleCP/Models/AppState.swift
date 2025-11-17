import Foundation
import SwiftUI

// Central app state management
@MainActor
class AppState: ObservableObject {
    // History data
    @Published var historyItems: [ClipboardItem] = []
    @Published var historyFolders: [HistoryFolder] = []

    // Snippet data
    @Published var snippetFolders: [SnippetFolder] = []

    // Search
    @Published var searchQuery: String = ""
    @Published var searchResults: SearchResults?
    @Published var isSearching: Bool = false

    // UI State
    @Published var selectedHistoryItem: ClipboardItem?
    @Published var selectedSnippetItem: ClipboardItem?
    @Published var showingSaveSnippetDialog: Bool = false
    @Published var itemToSave: ClipboardItem?
    @Published var showingSettings: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Computed property for available snippet folder names
    var snippetFolderNames: [String] {
        snippetFolders.map { $0.name }.sorted()
    }

    // Update snippet folders from API response
    func updateSnippets(from response: [String: [ClipboardItem]]) {
        snippetFolders = response.map { (name, items) in
            SnippetFolder(name: name, items: items, isExpanded: true)
        }.sorted { $0.name < $1.name }
    }

    // Toggle folder expansion
    func toggleFolder(name: String) {
        if let index = snippetFolders.firstIndex(where: { $0.name == name }) {
            snippetFolders[index].isExpanded.toggle()
        }
    }

    // Show save snippet dialog
    func showSaveDialog(for item: ClipboardItem) {
        itemToSave = item
        showingSaveSnippetDialog = true
    }

    // Clear search
    func clearSearch() {
        searchQuery = ""
        searchResults = nil
        isSearching = false
    }
}
