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

    // API client
    private let apiBaseURL = "http://127.0.0.1:8000"
    private let urlSession = URLSession.shared

    // Storage keys (fallback for offline mode)
    private let historyKey = "clipboardHistory"
    private let snippetsKey = "savedSnippets"
    private let foldersKey = "snippetFolders"

    // MARK: - API Response Models

    private struct APIClipboardItem: Codable {
        let clip_id: String
        let content: String
        let timestamp: String
        let content_type: String
        let display_string: String
        let source_app: String?
        let item_type: String
        let has_name: Bool
        let snippet_name: String?
        let folder_path: String?
        let tags: [String]
    }

    private struct APISnippetFolder: Codable {
        let folder_name: String
        let snippets: [APIClipboardItem]
    }

    private struct CreateSnippetRequest: Codable {
        let content: String
        let name: String
        let folder: String
        let tags: [String]
    }

    private struct CreateFolderRequest: Codable {
        let folder_name: String
    }

    private struct UpdateSnippetRequest: Codable {
        let content: String?
        let name: String?
        let tags: [String]?
    }

    // MARK: - API Communication Methods

    private func makeAPIRequest<T: Codable>(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: "\(apiBaseURL)\(endpoint)") else {
            throw AppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw AppError.networkError("HTTP \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func makeAPIRequestNoResponse(endpoint: String, method: String = "POST", body: Data? = nil) async throws {
        guard let url = URL(string: "\(apiBaseURL)\(endpoint)") else {
            throw AppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = body
        }

        let (_, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw AppError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }

    // MARK: - API Conversion Methods

    private func convertHexToUUID(_ hexString: String) -> UUID {
        // If it's already a valid UUID, use it
        if let uuid = UUID(uuidString: hexString) {
            return uuid
        }

        // Convert hex string to UUID format
        // Pad with zeros if necessary and format as UUID
        let paddedHex = String(hexString.prefix(32)).padding(toLength: 32, withPad: "0", startingAt: 0)

        // Break down the conversion step by step
        let part1 = String(paddedHex.prefix(8))
        let part2 = String(paddedHex.dropFirst(8).prefix(4))
        let part3 = String(paddedHex.dropFirst(12).prefix(4))
        let part4 = String(paddedHex.dropFirst(16).prefix(4))
        let part5 = String(paddedHex.dropFirst(20))

        let uuidString = "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"

        return UUID(uuidString: uuidString) ?? UUID()
    }

    private func convertToClipItem(_ apiItem: APIClipboardItem) -> ClipItem {
        // Convert string timestamp to Date
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.date(from: apiItem.timestamp) ?? Date()

        // Convert content type
        let contentType: ClipItem.ContentType = {
            switch apiItem.content_type.lowercased() {
            case "url": return .url
            case "email": return .email
            case "code": return .code
            case "text": return .text
            default: return .unknown
            }
        }()

        return ClipItem(
            id: convertHexToUUID(apiItem.clip_id),
            content: apiItem.content,
            timestamp: timestamp,
            contentType: contentType
        )
    }

    private func convertToSnippet(_ apiItem: APIClipboardItem, folderId: UUID?) -> Snippet {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.date(from: apiItem.timestamp) ?? Date()

        return Snippet(
            id: convertHexToUUID(apiItem.clip_id),
            name: apiItem.snippet_name ?? "Untitled",
            content: apiItem.content,
            tags: apiItem.tags,
            createdAt: timestamp,
            modifiedAt: timestamp,
            folderId: folderId,
            isFavorite: false
        )
    }

    private func findOrCreateFolder(_ folderName: String) -> UUID {
        // Find existing folder by name
        if let existingFolder = folders.first(where: { $0.name == folderName }) {
            return existingFolder.id
        }

        // Create new folder
        let newFolder = SnippetFolder(name: folderName, order: folders.count)
        folders.append(newFolder)
        return newFolder.id
    }

    init() {
        Task {
            await loadData()
        }
        startMonitoring()
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
        Task {
            do {
                // Find folder name for API call
                let folderName = folders.first(where: { $0.id == folderId })?.name ?? "General"

                // Create API request
                let request = CreateSnippetRequest(
                    content: content,
                    name: name,
                    folder: folderName,
                    tags: tags
                )

                let requestData = try JSONEncoder().encode(request)
                let _: APIClipboardItem = try await makeAPIRequest(
                    endpoint: "/api/snippets",
                    method: "POST",
                    body: requestData
                )

                logger.info("✅ Saved snippet '\(name)' to API")
            } catch {
                logger.warning("⚠️ Failed to save snippet to API, saving locally: \(error.localizedDescription)")
            }

            // Always save locally as backup/cache
            await MainActor.run {
                let snippet = Snippet(
                    name: name,
                    content: content,
                    tags: tags,
                    folderId: folderId
                )
                snippets.append(snippet)
                saveSnippets()
                logger.info("💾 Saved snippet locally: \(name)")
            }
        }
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

    func createFolder(name: String, icon: String = "📁", completion: (() -> Void)? = nil) {
        Task {
            do {
                // Create API request
                let request = CreateFolderRequest(folder_name: name)
                let requestData = try JSONEncoder().encode(request)

                try await makeAPIRequestNoResponse(
                    endpoint: "/api/folders",
                    method: "POST",
                    body: requestData
                )

                logger.info("✅ Created folder '\(name)' in API")
            } catch {
                logger.warning("⚠️ Failed to create folder in API, saving locally: \(error.localizedDescription)")
            }

            // Always save locally as backup/cache
            await MainActor.run {
                // Simple approach: Insert at beginning with order 0, existing folders keep their current order
                let folder = SnippetFolder(name: name, icon: icon, order: 0)
                folders.insert(folder, at: 0)
                saveFolders()
                logger.info("📁 Created folder locally: \(name)")

                // Call completion on main thread
                completion?()
            }
        }
    }

    func updateFolder(_ folder: SnippetFolder) {
        // Find the original folder to get the old name for API update
        guard let index = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        let originalFolder = folders[index]

        Task {
            do {
                // If folder name changed, call rename API
                if originalFolder.name != folder.name {
                    let request = ["new_name": folder.name]
                    let requestData = try JSONEncoder().encode(request)

                    try await makeAPIRequestNoResponse(
                        endpoint: "/api/folders/\(originalFolder.name)",
                        method: "PUT",
                        body: requestData
                    )

                    logger.info("✅ Renamed folder '\(originalFolder.name)' to '\(folder.name)' in API")
                }
            } catch {
                logger.warning("⚠️ Failed to update folder in API: \(error.localizedDescription)")
            }

            // Always update locally as backup/cache
            await MainActor.run {
                folders[index] = folder
                saveFolders()
                logger.info("✏️ Updated folder locally: \(folder.name)")
            }
        }
    }

    func deleteFolder(_ folder: SnippetFolder) {
        let snippetCount = snippets.filter { $0.folderId == folder.id }.count

        Task {
            do {
                // Delete folder via API
                try await makeAPIRequestNoResponse(
                    endpoint: "/api/folders/\(folder.name)",
                    method: "DELETE"
                )

                logger.info("✅ Deleted folder '\(folder.name)' from API")
            } catch {
                logger.warning("⚠️ Failed to delete folder from API: \(error.localizedDescription)")
            }

            // Always delete locally as backup/cache
            await MainActor.run {
                // Remove snippets in this folder
                snippets.removeAll { $0.folderId == folder.id }
                folders.removeAll { $0.id == folder.id }
                saveFolders()
                saveSnippets()
                logger.info("🗑️ Deleted folder '\(folder.name)' and \(snippetCount) snippets locally")
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
        // History is automatically captured by the backend via clipboard monitoring
        // For offline fallback, still save to UserDefaults
        do {
            let encoded = try JSONEncoder().encode(clipHistory)
            userDefaults.set(encoded, forKey: historyKey)
            logger.debug("💾 Saved \(self.clipHistory.count) clips to local storage (fallback)")
        } catch {
            lastError = .encodingFailure("clipboard history")
            showError = true
            logger.error("❌ Failed to save history: \(error.localizedDescription)")
        }
    }

    private func saveSnippets() {
        // Individual snippet operations use API calls directly
        // This method is for offline fallback storage only
        do {
            let encoded = try JSONEncoder().encode(snippets)
            userDefaults.set(encoded, forKey: snippetsKey)
            logger.debug("💾 Saved \(self.snippets.count) snippets to local storage (fallback)")
        } catch {
            lastError = .encodingFailure("snippets")
            showError = true
            logger.error("❌ Failed to save snippets: \(error.localizedDescription)")
        }
    }

    private func saveFolders() {
        // Individual folder operations use API calls directly
        // This method is for offline fallback storage only
        do {
            let encoded = try JSONEncoder().encode(folders)
            userDefaults.set(encoded, forKey: foldersKey)
            logger.debug("💾 Saved \(self.folders.count) folders to local storage (fallback)")
        } catch {
            lastError = .encodingFailure("folders")
            showError = true
            logger.error("❌ Failed to save folders: \(error.localizedDescription)")
        }
    }

    private func loadData() async {
        do {
            // Try to load from API first
            try await loadFromAPI()
        } catch {
            // Fallback to local storage if API is unavailable
            logger.warning("🔌 API unavailable, loading from local storage: \(error.localizedDescription)")
            await loadFromUserDefaults()
        }

        // Get current clipboard
        if let content = NSPasteboard.general.string(forType: .string) {
            await MainActor.run {
                currentClipboard = content
            }
            logger.debug("📋 Current clipboard loaded")
        }
    }

    private func loadFromAPI() async throws {
        logger.info("🔌 Loading data from API...")

        // Load history from API
        let apiHistory: [APIClipboardItem] = try await makeAPIRequest(endpoint: "/api/history/recent")
        await MainActor.run {
            clipHistory = apiHistory.map { convertToClipItem($0) }
        }
        logger.info("✅ Loaded \(apiHistory.count) clips from API")

        // Load snippets from API
        let apiSnippetFolders: [APISnippetFolder] = try await makeAPIRequest(endpoint: "/api/snippets")
        await MainActor.run {
            // Clear existing data
            snippets.removeAll()
            folders.removeAll()

            // Convert API data to local models
            for apiFolder in apiSnippetFolders {
                let folderId = findOrCreateFolder(apiFolder.folder_name)

                for apiSnippet in apiFolder.snippets {
                    let snippet = convertToSnippet(apiSnippet, folderId: folderId)
                    snippets.append(snippet)
                }
            }

            // Ensure we have default folders if none exist
            if folders.isEmpty {
                folders = SnippetFolder.defaultFolders()
            }
        }
        logger.info("✅ Loaded \(self.snippets.count) snippets and \(self.folders.count) folders from API")
    }

    private func loadFromUserDefaults() async {
        await MainActor.run {
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
        }
    }

    deinit {
        stopMonitoring()
    }
}
