//
//  ClipboardManager.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import Foundation
import AppKit
import Combine
import os.log

class ClipboardManager: ObservableObject {
    @Published var clipHistory: [ClipItem] = []
    @Published var snippets: [Snippet] = []
    @Published var folders: [SnippetFolder] = []
    @Published var currentClipboard: String = ""
    @Published var lastError: AppError? = nil
    @Published var showError: Bool = false

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let maxHistorySize: Int = 50
    private let userDefaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.simplecp.app", category: "clipboard")

    // Storage keys
    private let historyKey = "clipboardHistory"
    private let snippetsKey = "savedSnippets"
    private let foldersKey = "snippetFolders"

    init() {
        loadData()
        startMonitoring()
        // CRITICAL FIX: Sync with backend on startup
        syncWithBackend()
    }

    // MARK: - Clipboard Monitoring

    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }

        // CRITICAL FIX: Add timer to RunLoop to ensure it fires during UI events
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }

        logger.info("📋 Clipboard monitoring started")
    }

    // MARK: - Backend Synchronization

    private func syncWithBackend() {
        Task {
            await syncWithBackendAsync()
        }
    }

    private func syncWithBackendAsync() async {
        do {
            logger.info("🔄 Syncing folders with backend...")

            // Fetch current folder names from backend
            let backendFolders = try await APIClient.shared.fetchFolderNames()

            await MainActor.run {
                // Update existing folders and add new ones while preserving IDs
                var updatedFolders = self.folders

                // Remove folders that no longer exist in backend
                updatedFolders.removeAll { folder in
                    !backendFolders.contains(folder.name)
                }

                // Add new folders from backend
                for (index, folderName) in backendFolders.enumerated() {
                    if !updatedFolders.contains(where: { $0.name == folderName }) {
                        // Create new folder for backend-only folders
                        let newFolder = SnippetFolder(name: folderName, icon: "📁", order: index)
                        updatedFolders.append(newFolder)
                    }
                }

                // Update folder order to match backend order
                for (index, folderName) in backendFolders.enumerated() {
                    if let folderIndex = updatedFolders.firstIndex(where: { $0.name == folderName }) {
                        var folder = updatedFolders[folderIndex]
                        folder.order = index
                        folder.modifiedAt = Date()
                        updatedFolders[folderIndex] = folder
                    }
                }

                // Sort by order to match backend ordering
                updatedFolders.sort { $0.order < $1.order }

                // Update local state while preserving existing folder IDs
                self.folders = updatedFolders
                self.saveFolders()

                self.logger.info("✅ Synced \(self.folders.count) folders with backend")
            }
        } catch {
            await MainActor.run {
                logger.error("❌ Failed to sync with backend: \(error.localizedDescription)")
                // Continue with local folders if backend sync fails
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        logger.info("📋 Clipboard monitoring stopped")
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }

        lastChangeCount = pasteboard.changeCount

        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            currentClipboard = content
            addToHistory(content: content)
            logger.debug("📋 New clipboard item detected: \(content.prefix(50))...")
        }
    }

    // MARK: - History Management

    func addToHistory(content: String) {
        // Avoid duplicates
        if let existingIndex = clipHistory.firstIndex(where: { $0.content == content }) {
            // Move to top if it already exists
            let item = clipHistory.remove(at: existingIndex)
            clipHistory.insert(item, at: 0)
            logger.debug("📋 Moved existing clip to top")
        } else {
            // Add new item
            let contentType = detectContentType(content)
            let newItem = ClipItem(content: content, contentType: contentType)
            clipHistory.insert(newItem, at: 0)

            // Limit history size
            if clipHistory.count > maxHistorySize {
                clipHistory = Array(clipHistory.prefix(maxHistorySize))
                logger.debug("📋 Trimmed history to \(self.maxHistorySize) items")
            }

            logger.info("📋 Added new clip to history (type: \(String(describing: contentType)))")
        }

        saveHistory()
    }

    func removeFromHistory(item: ClipItem) {
        clipHistory.removeAll { $0.id == item.id }
        saveHistory()
        logger.info("🗑️ Removed clip from history")
    }

    func clearHistory() {
        let count = clipHistory.count
        clipHistory.removeAll()
        saveHistory()
        logger.info("🗑️ Cleared all \(count) clips from history")
    }

    func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastChangeCount = pasteboard.changeCount
        currentClipboard = content
        logger.debug("📋 Copied to clipboard: \(content.prefix(50))...")
    }

    private func detectContentType(_ content: String) -> ClipItem.ContentType {
        // Simple content type detection
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return .url
        } else if content.contains("@") && content.contains(".") && !content.contains(" ") {
            return .email
        } else if content.contains("{") || content.contains("func ") || content.contains("import ") {
            return .code
        }
        return .text
    }

    // MARK: - Snippet Management

    func saveAsSnippet(name: String, content: String, folderId: UUID?, tags: [String] = []) {
        let snippet = Snippet(
            name: name,
            content: content,
            tags: tags,
            folderId: folderId
        )
        snippets.append(snippet)
        saveSnippets()
        logger.info("💾 Saved snippet: \(name)")
    }

    func updateSnippet(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
            saveSnippets()
            logger.info("✏️ Updated snippet: \(snippet.name)")
        }
    }

    func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        saveSnippets()
        logger.info("🗑️ Deleted snippet: \(snippet.name)")
    }

    func getSnippets(for folderId: UUID) -> [Snippet] {
        snippets.filter { $0.folderId == folderId }
    }

    func suggestSnippetName(for content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? ""

        if firstLine.isEmpty {
            return "Untitled Snippet"
        }

        // Take first 50 characters or first line
        let preview = String(firstLine.prefix(50))
        return preview
    }

    // MARK: - Folder Management

    func createFolder(name: String, icon: String = "📁") {
        // Insert new folders at the top (order 0)
        let folder = SnippetFolder(name: name, icon: icon, order: 0)

        // Increment order of all existing folders
        for index in folders.indices {
            folders[index].order += 1
        }

        // Insert new folder at the beginning
        folders.insert(folder, at: 0)
        saveFolders()

        // Sync with backend
        Task {
            do {
                try await APIClient.shared.createFolder(name: name)
                await MainActor.run {
                    logger.info("📁 Created folder: \(name) (synced with backend)")
                }
            } catch {
                await MainActor.run {
                    logger.error("❌ Failed to sync folder creation with backend: \(error.localizedDescription)")
                    lastError = .apiError("Failed to sync folder creation: \(error.localizedDescription)")
                    showError = true
                }
            }
        }
    }

    func updateFolder(_ folder: SnippetFolder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            let oldFolder = folders[index]
            let oldName = oldFolder.name
            let newName = folder.name

            // Update local state first
            folders[index] = folder
            saveFolders()

            // If name changed, sync with backend
            if oldName != newName {
                Task {
                    do {
                        try await APIClient.shared.renameFolder(oldName: oldName, newName: newName)
                        await MainActor.run {
                            logger.info("✏️ Folder renamed: '\(oldName)' → '\(newName)' (synced with backend)")
                        }
                        // Note: No need to re-sync with backend here as local state is already updated
                        // Re-syncing causes unnecessary state changes and view recreations
                    } catch {
                        await MainActor.run {
                            logger.error("❌ Failed to sync folder rename with backend: \(error.localizedDescription)")
                            lastError = .apiError("Failed to sync folder rename: \(error.localizedDescription)")
                            showError = true
                            // Revert local change on API failure
                            folders[index] = oldFolder
                            saveFolders()
                        }
                    }
                }
            } else {
                logger.info("✏️ Updated folder: \(folder.name)")
            }
        }
    }

    func deleteFolder(_ folder: SnippetFolder) {
        let snippetCount = snippets.filter { $0.folderId == folder.id }.count
        // Remove snippets in this folder
        snippets.removeAll { $0.folderId == folder.id }
        folders.removeAll { $0.id == folder.id }
        saveFolders()
        saveSnippets()

        // Sync with backend
        Task {
            do {
                try await APIClient.shared.deleteFolder(name: folder.name)
                await MainActor.run {
                    logger.info("🗑️ Deleted folder '\(folder.name)' and \(snippetCount) snippets (synced with backend)")
                }
            } catch {
                await MainActor.run {
                    logger.error("❌ Failed to sync folder deletion with backend: \(error.localizedDescription)")
                    lastError = .apiError("Failed to sync folder deletion: \(error.localizedDescription)")
                    showError = true
                }
            }
        }
    }

    func toggleFolderExpansion(_ folderId: UUID) {
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            folders[index].toggleExpanded()
            saveFolders()
        }
    }

    // MARK: - Search

    func search(query: String) -> (clips: [ClipItem], snippets: [Snippet]) {
        let lowercaseQuery = query.lowercased()

        let filteredClips = clipHistory.filter { clip in
            clip.content.lowercased().contains(lowercaseQuery)
        }

        let filteredSnippets = snippets.filter { snippet in
            snippet.name.lowercased().contains(lowercaseQuery) ||
            snippet.content.lowercased().contains(lowercaseQuery) ||
            snippet.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }

        logger.debug("🔍 Search '\(query)': \(filteredClips.count) clips, \(filteredSnippets.count) snippets")

        return (filteredClips, filteredSnippets)
    }

    // MARK: - Persistence (Improved with Error Handling)

    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(clipHistory)
            userDefaults.set(encoded, forKey: historyKey)
            logger.debug("💾 Saved \(self.clipHistory.count) clips to storage")
        } catch {
            lastError = .encodingFailure("clipboard history")
            showError = true
            logger.error("❌ Failed to save history: \(error.localizedDescription)")
        }
    }

    private func saveSnippets() {
        do {
            let encoded = try JSONEncoder().encode(snippets)
            userDefaults.set(encoded, forKey: snippetsKey)
            logger.debug("💾 Saved \(self.snippets.count) snippets to storage")
        } catch {
            lastError = .encodingFailure("snippets")
            showError = true
            logger.error("❌ Failed to save snippets: \(error.localizedDescription)")
        }
    }

    private func saveFolders() {
        do {
            let encoded = try JSONEncoder().encode(folders)
            userDefaults.set(encoded, forKey: foldersKey)
            logger.debug("💾 Saved \(self.folders.count) folders to storage")
        } catch {
            lastError = .encodingFailure("folders")
            showError = true
            logger.error("❌ Failed to save folders: \(error.localizedDescription)")
        }
    }

    private func loadData() {
        // Load history with error handling
        if let data = userDefaults.data(forKey: historyKey) {
            do {
                clipHistory = try JSONDecoder().decode([ClipItem].self, from: data)
                logger.info("✅ Loaded \(self.clipHistory.count) clips from storage")
            } catch {
                logger.error("⚠️ Failed to load history: \(error.localizedDescription). Starting fresh.")
                clipHistory = []
            }
        }

        // Load snippets with error handling
        if let data = userDefaults.data(forKey: snippetsKey) {
            do {
                snippets = try JSONDecoder().decode([Snippet].self, from: data)
                logger.info("✅ Loaded \(self.snippets.count) snippets from storage")
            } catch {
                logger.error("⚠️ Failed to load snippets: \(error.localizedDescription). Starting fresh.")
                snippets = []
            }
        }

        // Load folders with error handling
        if let data = userDefaults.data(forKey: foldersKey) {
            do {
                folders = try JSONDecoder().decode([SnippetFolder].self, from: data)
                logger.info("✅ Loaded \(self.folders.count) folders from storage")
            } catch {
                logger.error("⚠️ Failed to load folders: \(error.localizedDescription). Creating defaults.")
                folders = SnippetFolder.defaultFolders()
                saveFolders()
            }
        } else {
            // Create default folders if none exist
            folders = SnippetFolder.defaultFolders()
            saveFolders()
            logger.info("✅ Created default folders")
        }

        // Get current clipboard
        if let content = NSPasteboard.general.string(forType: .string) {
            currentClipboard = content
            logger.debug("📋 Current clipboard loaded")
        }
    }

    deinit {
        stopMonitoring()
    }
}
