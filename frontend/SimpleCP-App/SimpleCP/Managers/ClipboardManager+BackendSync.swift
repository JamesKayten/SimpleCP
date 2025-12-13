//
//  ClipboardManager+BackendSync.swift
//  SimpleCP
//
//  Backend synchronization and content validation
//

import Foundation

extension ClipboardManager {
    // MARK: - Backend Connection with Exponential Backoff

    /// Waits for backend to be ready and then syncs, using exponential backoff
    func waitForBackendAndSync() async {
        logger.info("🔄 Waiting for backend to be ready before initial sync...")

        for attempt in 0..<10 {
            let delay = min(0.5 * pow(1.5, Double(attempt)), 5.0)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            let port = UserDefaults.standard.integer(forKey: "apiPort")
            let effectivePort = port > 0 ? port : 49917
            if let url = URL(string: "http://127.0.0.1:\(effectivePort)/health"),
               let (_, response) = try? await URLSession.shared.data(from: url),
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                logger.info("🟢 Backend ready after \(String(format: "%.1f", delay))s on attempt \(attempt + 1), starting sync...")
                await syncWithBackendAsync()
                return
            }
        }

        logger.warning("⚠️ Backend not responding after multiple attempts, using local data only")
    }

    // MARK: - Backend Synchronization

    func syncWithBackend() {
        Task { await syncWithBackendAsync() }
    }

    func syncWithBackendAsync() async {
        do {
            logger.info("🔄 Syncing folders with backend...")
            let backendFolders = try await APIClient.shared.fetchFolderNames()

            await MainActor.run {
                var updatedFolders = self.folders

                let localOnlyFolders = updatedFolders.filter { folder in
                    !backendFolders.contains(folder.name)
                }

                if !localOnlyFolders.isEmpty {
                    self.logger.info("📤 Found \(localOnlyFolders.count) local-only folders to sync to backend")
                    Task {
                        for folder in localOnlyFolders {
                            do {
                                try await APIClient.shared.createFolder(name: folder.name)
                                self.logger.info("✅ Synced local folder '\(folder.name)' to backend")
                            } catch APIError.httpError(let statusCode, _) where statusCode == 409 {
                                self.logger.debug("ℹ️ Folder '\(folder.name)' already exists on backend")
                            } catch {
                                self.logger.warning("⚠️ Failed to sync folder '\(folder.name)' to backend: \(error.localizedDescription)")
                            }
                        }
                    }
                }

                for (index, folderName) in backendFolders.enumerated() {
                    if !updatedFolders.contains(where: { $0.name == folderName }) {
                        #if DEBUG
                        logger.debug("📥 SYNC: Adding folder from backend: '\(folderName, privacy: .public)'")
                        #endif
                        let newFolder = SnippetFolder(name: folderName, icon: "📁", order: index)
                        updatedFolders.append(newFolder)
                    }
                }

                for (index, folderName) in backendFolders.enumerated() {
                    if let folderIndex = updatedFolders.firstIndex(where: { $0.name == folderName }) {
                        var folder = updatedFolders[folderIndex]
                        folder.order = index
                        folder.modifiedAt = Date()
                        updatedFolders[folderIndex] = folder
                    }
                }

                updatedFolders.sort { $0.order < $1.order }
                self.folders = updatedFolders
                self.saveFolders()
                self.logger.info("✅ Synced \(self.folders.count) folders with backend")
            }
        } catch {
            await MainActor.run {
                logger.error("❌ Failed to sync with backend: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Content Validation

    /// Basic content validation
    func shouldStoreContent(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 3 || trimmed.isEmpty { return false }

        let consolePatterns = [
            "📡 API:", "❌ API Error:", "✅ Snippet", "💾 save", "🗑️ Removed",
            "Backend stdout:", "nw_socket_handle_socket_event", "nw_endpoint_flow",
            "INFO:     127.0.0.1:", "⚠️ Create snippet", "🎨 Applying window"
        ]

        for pattern in consolePatterns {
            if content.contains(pattern) {
                logger.info("📋 Skipped console/log output from clipboard")
                return false
            }
        }

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
    func sanitizeForLogging(_ content: String) -> String {
        if content.count > 50 { return "\(content.prefix(50))..." }
        return content
    }
}
