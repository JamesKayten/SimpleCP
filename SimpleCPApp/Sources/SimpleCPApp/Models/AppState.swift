//
//  AppState.swift
//  SimpleCPApp
//
//  Application state management
//

import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var historyItems: [ClipboardItem] = []
    @Published var historyFolders: [HistoryFolder] = []
    @Published var snippetFolders: [SnippetFolder] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedHistoryItem: ClipboardItem?
    @Published var selectedSnippetItem: ClipboardItem?

    let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Data Loading
    func loadAllData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load history
            await loadHistory()
            // Load snippets
            await loadSnippets()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
    }

    func loadHistory() async {
        do {
            let recent = try await apiClient.getRecentHistory()
            let folders = try await apiClient.getHistoryFolders()
            historyItems = recent
            historyFolders = folders
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
        }
    }

    func loadSnippets() async {
        do {
            let snippetsDict = try await apiClient.getSnippets()
            snippetFolders = snippetsDict.map { (name, items) in
                SnippetFolder(name: name, items: items)
            }.sorted { $0.name < $1.name }
        } catch {
            errorMessage = "Failed to load snippets: \(error.localizedDescription)"
        }
    }

    // MARK: - History Operations
    func deleteHistoryItem(_ item: ClipboardItem) async {
        do {
            try await apiClient.deleteHistoryItem(id: item.clipId)
            await loadHistory()
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    func clearHistory() async {
        do {
            try await apiClient.clearHistory()
            await loadHistory()
        } catch {
            errorMessage = "Failed to clear history: \(error.localizedDescription)"
        }
    }

    // MARK: - Snippet Operations
    func createSnippet(from item: ClipboardItem?, name: String, folder: String, tags: [String]) async {
        do {
            let request = CreateSnippetRequest(
                clipId: item?.clipId,
                content: item?.content,
                name: name,
                folder: folder,
                tags: tags
            )
            _ = try await apiClient.createSnippet(request: request)
            await loadSnippets()
        } catch {
            errorMessage = "Failed to create snippet: \(error.localizedDescription)"
        }
    }

    func deleteSnippet(folder: String, item: ClipboardItem) async {
        do {
            try await apiClient.deleteSnippet(folder: folder, id: item.clipId)
            await loadSnippets()
        } catch {
            errorMessage = "Failed to delete snippet: \(error.localizedDescription)"
        }
    }

    func updateSnippet(folder: String, item: ClipboardItem, newContent: String?, newName: String?, newTags: [String]?) async {
        do {
            let request = UpdateSnippetRequest(content: newContent, name: newName, tags: newTags)
            try await apiClient.updateSnippet(folder: folder, id: item.clipId, request: request)
            await loadSnippets()
        } catch {
            errorMessage = "Failed to update snippet: \(error.localizedDescription)"
        }
    }

    // MARK: - Folder Operations
    func createFolder(name: String) async {
        do {
            try await apiClient.createFolder(name: name)
            await loadSnippets()
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
        }
    }

    func renameFolder(oldName: String, newName: String) async {
        do {
            try await apiClient.renameFolder(oldName: oldName, newName: newName)
            await loadSnippets()
        } catch {
            errorMessage = "Failed to rename folder: \(error.localizedDescription)"
        }
    }

    func deleteFolder(name: String) async {
        do {
            try await apiClient.deleteFolder(name: name)
            await loadSnippets()
        } catch {
            errorMessage = "Failed to delete folder: \(error.localizedDescription)"
        }
    }

    // MARK: - Clipboard Operations
    func copyToClipboard(item: ClipboardItem) async {
        do {
            try await apiClient.copyToClipboard(itemId: item.clipId)
        } catch {
            errorMessage = "Failed to copy to clipboard: \(error.localizedDescription)"
        }
    }

    // MARK: - Search
    func performSearch() async {
        guard !searchQuery.isEmpty else {
            await loadAllData()
            return
        }

        do {
            let results = try await apiClient.search(query: searchQuery)
            historyItems = results.history
            // Convert snippet results to folders
            snippetFolders = Dictionary(grouping: results.snippets) { $0.folderPath ?? "Uncategorized" }
                .map { SnippetFolder(name: $0.key, items: $0.value) }
                .sorted { $0.name < $1.name }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Folder Expansion
    func toggleFolderExpansion(folder: SnippetFolder) {
        if let index = snippetFolders.firstIndex(where: { $0.id == folder.id }) {
            snippetFolders[index].isExpanded.toggle()
        }
    }
}
