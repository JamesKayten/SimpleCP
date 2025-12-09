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
    private var ignoreNextChange: Bool = false

    // Storage keys
    let historyKey = "clipboardHistory"
    let snippetsKey = "savedSnippets"
    let foldersKey = "snippetFolders"
    
    // MARK: - Flyout Delay Settings
    
    /// Delay in seconds before showing clip preview popovers (default: 0.7s)
    var clipPreviewDelay: TimeInterval {
        get { userDefaults.double(forKey: "clipPreviewDelay") == 0 ? 0.7 : userDefaults.double(forKey: "clipPreviewDelay") }
        set { userDefaults.set(newValue, forKey: "clipPreviewDelay") }
    }
    
    /// Delay in seconds before showing clip group flyouts (default: 0.5s)
    var clipGroupFlyoutDelay: TimeInterval {
        get { userDefaults.double(forKey: "clipGroupFlyoutDelay") == 0 ? 0.5 : userDefaults.double(forKey: "clipGroupFlyoutDelay") }
        set { userDefaults.set(newValue, forKey: "clipGroupFlyoutDelay") }
    }
    
    /// Delay in seconds before showing folder flyouts (default: 1.0s)
    var folderFlyoutDelay: TimeInterval {
        get { 
            let value = userDefaults.double(forKey: "folderFlyoutDelay")
            return value == 0 ? 1.0 : value
        }
        set { userDefaults.set(newValue, forKey: "folderFlyoutDelay") }
    }

    init() {
        loadData()
        startMonitoring()
        
        // Sync with backend using exponential backoff
        Task {
            await waitForBackendAndSync()
        }
    }
    
    // MARK: - Backend Connection with Exponential Backoff
    
    /// Waits for backend to be ready and then syncs, using exponential backoff
    private func waitForBackendAndSync() async {
        logger.info("🔄 Waiting for backend to be ready before initial sync...")
        
        for attempt in 0..<10 {
            let delay = min(0.5 * pow(1.5, Double(attempt)), 5.0) // Max 5 seconds per attempt
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Try a quick health check - use IPv4 explicitly to avoid resolution issues
            if let url = URL(string: "http://127.0.0.1:49917/health"),
               let (_, response) = try? await URLSession.shared.data(from: url),
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                logger.info("🟢 Backend ready after \(String(format: "%.1f", delay))s on attempt \(attempt + 1), starting sync...")
                await syncWithBackendAsync()
                return
            }
        }
        
        // If we couldn't connect after max attempts, sync anyway (will use local data)
        logger.warning("⚠️ Backend not responding after multiple attempts, using local data only")
        // Don't sync with backend - just use local folders
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

                // FIXED: Don't remove local-only folders - push them to backend instead!
                // Check for local-only folders that need to be synced to backend
                let localOnlyFolders = updatedFolders.filter { folder in
                    !backendFolders.contains(folder.name)
                }
                
                // Push local-only folders to backend
                if !localOnlyFolders.isEmpty {
                    self.logger.info("📤 Found \(localOnlyFolders.count) local-only folders to sync to backend")
                    Task {
                        for folder in localOnlyFolders {
                            do {
                                try await APIClient.shared.createFolder(name: folder.name)
                                self.logger.info("✅ Synced local folder '\(folder.name)' to backend")
                            } catch APIError.httpError(let statusCode, _) where statusCode == 409 {
                                // 409 conflict means folder already exists - that's fine
                                self.logger.debug("ℹ️ Folder '\(folder.name)' already exists on backend")
                            } catch {
                                self.logger.warning("⚠️ Failed to sync folder '\(folder.name)' to backend: \(error.localizedDescription)")
                                // Keep the local folder even if sync fails
                            }
                        }
                    }
                }

                // Add new folders from backend that don't exist locally
                for (index, folderName) in backendFolders.enumerated() {
                    if !updatedFolders.contains(where: { $0.name == folderName }) {
                        // Create new folder for backend-only folders
                        #if DEBUG
                        logger.debug("📥 SYNC: Adding folder from backend: '\(folderName, privacy: .public)'")
                        #endif
                        let newFolder = SnippetFolder(name: folderName, icon: "📁", order: index)
                        updatedFolders.append(newFolder)
                    }
                }

                // Update folder order to match backend order for folders that exist in backend
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

        // Skip if we're ignoring programmatic changes
        if ignoreNextChange {
            ignoreNextChange = false
            logger.debug("📋 Ignoring programmatic clipboard change")
            return
        }

        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            // Check if content should be stored (basic validation)
            guard shouldStoreContent(content) else {
                logger.info("📋 Skipped storing sensitive or invalid clipboard content")
                return
            }
            
            currentClipboard = content
            addToHistory(content: content)
            
            // Use sanitized version for logging
            let sanitized = sanitizeForLogging(content)
            logger.debug("📋 New clipboard item: \(sanitized)")
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
        ignoreNextChange = true
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Try to set the string and verify it worked
        let success = pasteboard.setString(content, forType: .string)
        
        if success {
            // Verify the content was actually written
            if let readBack = pasteboard.string(forType: .string), readBack == content {
                lastChangeCount = pasteboard.changeCount
                currentClipboard = content
                logger.debug("📋 Successfully copied to clipboard (\(content.count) chars): \(content.prefix(50))...")
            } else {
                logger.error("❌ Clipboard verification failed - content mismatch")
                ignoreNextChange = false
            }
        } else {
            logger.error("❌ Failed to set clipboard content")
            ignoreNextChange = false
        }
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
    
    // MARK: - Basic Security Helpers
    
    /// Basic content validation (use SecurityManager when available)
    private func shouldStoreContent(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't store if too short
        if trimmed.count < 3 {
            return false
        }
        
        // Don't store if just whitespace
        if trimmed.isEmpty {
            return false
        }
        
        // Filter out Xcode console output patterns
        let lines = content.components(separatedBy: .newlines)
        _ = lines.first ?? ""
        
        // Check for console/log output patterns
        let consolePatterns = [
            "📡 API:",
            "❌ API Error:",
            "✅ Snippet",
            "💾 save",
            "🗑️ Removed",
            "Backend stdout:",
            "nw_socket_handle_socket_event",
            "nw_endpoint_flow",
            "INFO:     127.0.0.1:",
            "⚠️ Create snippet",
            "🎨 Applying window"
        ]
        
        for pattern in consolePatterns {
            if content.contains(pattern) {
                logger.info("📋 Skipped console/log output from clipboard")
                return false
            }
        }
        
        // Basic sensitive pattern detection
        let lowercased = content.lowercased()
        let sensitiveKeywords = ["password:", "api_key", "bearer ", "-----begin private key-----"]
        
        for keyword in sensitiveKeywords {
            if lowercased.contains(keyword) {
                logger.warning("🔒 Detected potentially sensitive content")
                return false
            }
        }
        
        return true
    }
    
    /// Sanitize content for logging
    private func sanitizeForLogging(_ content: String) -> String {
        if content.count > 50 {
            return "\(content.prefix(50))..."
        }
        return content
    }
    
    // MARK: - Folder Management
    
    @discardableResult
    func createFolder(name: String) -> SnippetFolder {
        let maxOrder = folders.map { $0.order }.max() ?? -1
        let newFolder = SnippetFolder(name: name, icon: "📁", order: maxOrder + 1)
        folders.append(newFolder)
        saveFolders()
        logger.info("📁 Created folder: \(name)")
        
        Task {
            do {
                try await APIClient.shared.createFolder(name: name)
                logger.info("✅ Folder synced with backend: \(name)")
            } catch {
                logger.warning("⚠️ Failed to sync folder with backend: \(error.localizedDescription)")
            }
        }
        
        return newFolder
    }
    
    func updateFolder(_ folder: SnippetFolder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            let oldName = folders[index].name
            folders[index] = folder
            saveFolders()
            logger.info("✏️ Updated folder: \(folder.name)")
            
            // If name changed, sync with backend
            if oldName != folder.name {
                Task {
                    do {
                        try await APIClient.shared.renameFolder(oldName: oldName, newName: folder.name)
                        logger.info("✅ Folder rename synced with backend")
                    } catch {
                        logger.warning("⚠️ Failed to sync folder rename with backend: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func deleteFolder(_ folder: SnippetFolder) {
        folders.removeAll { $0.id == folder.id }
        snippets.removeAll { $0.folderId == folder.id }
        saveFolders()
        saveSnippets()
        logger.info("🗑️ Deleted folder: \(folder.name)")
        
        Task {
            do {
                try await APIClient.shared.deleteFolder(name: folder.name)
                logger.info("✅ Folder deletion synced with backend")
            } catch {
                logger.warning("⚠️ Failed to sync folder deletion: \(error.localizedDescription)")
            }
        }
    }
}
