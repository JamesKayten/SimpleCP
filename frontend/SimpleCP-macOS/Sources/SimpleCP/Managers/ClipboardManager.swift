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

    var timer: Timer?
    var lastChangeCount: Int = 0
    let maxHistorySize: Int = 50
    let userDefaults = UserDefaults.standard
    let logger = Logger(subsystem: "com.simplecp.app", category: "clipboard")

    // Storage keys
    let historyKey = "clipboardHistory"
    let snippetsKey = "savedSnippets"
    let foldersKey = "snippetFolders"

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

    func syncWithBackend() {
        Task {
            await syncWithBackendAsync()
        }
    }

    func syncWithBackendAsync() async {
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
                        print("🟡🟡🟡 SYNC: Adding folder from backend: '\(folderName)'")
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

    func detectContentType(_ content: String) -> ClipItem.ContentType {
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

    deinit {
        stopMonitoring()
    }
}
