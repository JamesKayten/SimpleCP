//
//  ClipboardManager+Snippets.swift
//  SimpleCP
//
//  Snippet management extension for ClipboardManager
//

import Foundation
import AppKit

extension ClipboardManager {
    // MARK: - Snippet Management

    func saveAsSnippet(name: String, content: String, folderId: UUID?, tags: [String] = []) {
        #if DEBUG
        logger.debug("💾 saveAsSnippet called:")
        logger.debug("   - name: '\(name)'")
        logger.debug("   - folderId: \(folderId?.uuidString ?? "nil", privacy: .public)")
        logger.debug("   - content length: \(content.count)")
        logger.debug("   - existing snippets in folder: \(self.snippets.filter { $0.folderId == folderId }.count)")
        #endif
        
        // Check for duplicates in the same folder
        let existingSnippet = snippets.first { snippet in
            snippet.content == content && snippet.folderId == folderId
        }
        
        if let existing = existingSnippet {
            logger.warning("⚠️ Duplicate snippet detected: '\(existing.name)' in same folder - not creating duplicate")
            #if DEBUG
            logger.debug("❌ Duplicate detected, showing alert")
            #endif
            
            // Show alert on main thread
            DispatchQueue.main.async { [weak self] in
                self?.showDuplicateAlert(existing: existing, newName: name, folderId: folderId)
            }
            
            // Still remove from clip history even if duplicate
            if let clipToRemove = clipHistory.first(where: { $0.content == content }) {
                removeFromHistory(item: clipToRemove)
                logger.info("🗑️ Removed clip from history (duplicate snippet)")
            }
            return
        }
        
        #if DEBUG
        logger.debug("✅ No duplicate found, creating snippet...")
        #endif
        
        // IMPORTANT: Check if this content came from clipboard history BEFORE removing it
        // We need the clip ID for backend sync, but we'll remove it from history after
        let clipIdFromHistory: String?
        let clipToRemove: ClipItem?
        if let clipItem = clipHistory.first(where: { $0.content == content }) {
            // Save the clip ID for backend sync
            clipIdFromHistory = clipItem.id.uuidString.replacingOccurrences(of: "-", with: "").prefix(16).lowercased()
            clipToRemove = clipItem
            #if DEBUG
            logger.debug("📋 Found clip in history with ID: \(clipIdFromHistory!, privacy: .public)")
            #endif
        } else {
            clipIdFromHistory = nil
            clipToRemove = nil
            #if DEBUG
            logger.debug("📋 Content not from clipboard history")
            #endif
        }
        
        let snippet = Snippet(
            name: name,
            content: content,
            tags: tags,
            folderId: folderId
        )
        snippets.append(snippet)
        saveSnippets()
        logger.info("💾 Saved snippet: \(name)")
        
        #if DEBUG
        logger.debug("✅ Snippet saved successfully. Total snippets now: \(self.snippets.count)")
        #endif
        
        // Remove the clip from history since it's now saved as a snippet
        if let clipToRemove = clipToRemove {
            removeFromHistory(item: clipToRemove)
            logger.info("🗑️ Removed clip from history (now saved as snippet)")
            #if DEBUG
            logger.debug("✅ Removed clip from history")
            #endif
        } else {
            #if DEBUG
            logger.debug("⚠️ Clip not found in history to remove")
            #endif
        }

        // Sync with backend
        Task {
            do {
                // Get folder name from folderId
                let folderName: String
                if let folderId = folderId, let folder = folders.first(where: { $0.id == folderId }) {
                    folderName = folder.name
                    #if DEBUG
                    logger.debug("✅ Found folder for ID \(folderId): '\(folderName, privacy: .public)'")
                    #endif
                } else {
                    folderName = "General"
                    #if DEBUG
                    if let folderId = folderId {
                        logger.warning("⚠️ Folder ID \(folderId) not found in folders array! Using 'General' instead")
                        logger.debug("📋 Available folders: \(self.folders.map { "\($0.name) (\($0.id))" }.joined(separator: ", "), privacy: .public)")
                    } else {
                        logger.debug("ℹ️ No folder ID provided, using 'General'")
                    }
                    #endif
                }

                // Use the clip ID we saved earlier (if content was from history)
                if let clipId = clipIdFromHistory {
                    #if DEBUG
                    logger.debug("📡 Creating snippet '\(name, privacy: .public)' in folder '\(folderName, privacy: .public)' with clip_id '\(clipId, privacy: .public)' (from history)")
                    #endif
                } else {
                    #if DEBUG
                    logger.debug("📡 Creating snippet '\(name, privacy: .public)' in folder '\(folderName, privacy: .public)' without clip_id (not from history)")
                    #endif
                }

                try await APIClient.shared.createSnippet(
                    name: name,
                    content: content,
                    folder: folderName,
                    tags: tags,
                    clipId: clipIdFromHistory
                )
                await MainActor.run {
                    logger.info("💾 Snippet synced with backend: \(name)")
                }
            } catch APIError.httpError(let statusCode, let message) where statusCode == 404 {
                // 404 means backend couldn't find referenced history item
                // This happens when creating snippets from current clipboard that aren't in backend history
                // Keep local snippet since it was saved successfully
                await MainActor.run {
                    logger.warning("⚠️ Backend couldn't find history item (snippet saved locally only): \(message)")
                    // Don't show error to user - snippet is saved locally which is what they wanted
                }
            } catch APIError.httpError(let statusCode, let message) where statusCode >= 500 {
                // Server error - keep local snippet but warn user
                await MainActor.run {
                    logger.error("❌ Backend server error (HTTP \(statusCode)): \(message)")
                    // Optionally show a less intrusive warning
                    // Don't fail the whole operation since the snippet was saved locally
                }
            } catch APIError.networkError(let error) {
                // Network error - keep local snippet
                await MainActor.run {
                    logger.error("❌ Network error syncing snippet: \(error.localizedDescription)")
                    // Snippet is saved locally, sync can happen later
                }
            } catch {
                await MainActor.run {
                    logger.error("❌ Failed to sync snippet with backend: \(error.localizedDescription)")
                    lastError = .apiError("Failed to sync snippet: \(error.localizedDescription)")
                    showError = true
                }
            }
        }
    }

    func updateSnippet(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
            saveSnippets()
            logger.info("✏️ Updated snippet: \(snippet.name)")

            // Sync with backend
            Task {
                do {
                    // Get folder name from folderId
                    let folderName: String
                    if let folderId = snippet.folderId, let folder = folders.first(where: { $0.id == folderId }) {
                        folderName = folder.name
                    } else {
                        folderName = "General"
                    }

                    // Convert UUID to hex string for clip_id
                    let clipId = snippet.id.uuidString.replacingOccurrences(of: "-", with: "").prefix(16).lowercased()

                    try await APIClient.shared.updateSnippet(
                        folderName: folderName,
                        clipId: String(clipId),
                        content: snippet.content,
                        name: snippet.name,
                        tags: snippet.tags
                    )
                    await MainActor.run {
                        logger.info("✏️ Snippet update synced with backend: \(snippet.name)")
                    }
                } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
                    // 404 means snippet wasn't on backend - that's okay, keep local changes
                    await MainActor.run {
                        logger.info("ℹ️ Snippet was not on backend (local-only snippet)")
                    }
                } catch {
                    await MainActor.run {
                        logger.warning("⚠️ Failed to sync snippet update with backend: \(error.localizedDescription)")
                        // Don't revert or show error - local update is what user wanted
                    }
                }
            }
        }
    }

    func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        saveSnippets()
        logger.info("🗑️ Deleted snippet: \(snippet.name)")

        // Sync with backend
        Task {
            do {
                // Get folder name from folderId
                let folderName: String
                if let folderId = snippet.folderId, let folder = folders.first(where: { $0.id == folderId }) {
                    folderName = folder.name
                } else {
                    folderName = "General"
                }

                // Convert UUID to hex string for clip_id
                let clipId = snippet.id.uuidString.replacingOccurrences(of: "-", with: "").prefix(16).lowercased()

                try await APIClient.shared.deleteSnippet(
                    folderName: folderName,
                    clipId: String(clipId)
                )
                await MainActor.run {
                    logger.info("🗑️ Snippet deletion synced with backend: \(snippet.name)")
                }
            } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
                // 404 means snippet wasn't on backend - that's fine, it's deleted on frontend
                await MainActor.run {
                    logger.info("ℹ️ Snippet was not on backend (already deleted or never synced)")
                }
            } catch {
                await MainActor.run {
                    logger.warning("⚠️ Failed to sync snippet deletion with backend: \(error.localizedDescription)")
                    // Don't show error to user - snippet is already deleted locally which is what matters
                }
            }
        }
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
    
    // MARK: - Export/Import
    
    func exportFolder(_ folder: SnippetFolder) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "SimpleCP-\(folder.name)-\(Date().formatted(date: .abbreviated, time: .omitted)).json"
        panel.message = "Export folder '\(folder.name)' to a JSON file"
        
        if panel.runModal() == .OK, let url = panel.url {
            let folderSnippets = snippets.filter { $0.folderId == folder.id }
            let data = ExportData(
                snippets: folderSnippets,
                folders: [folder]
            )
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let encoded = try encoder.encode(data)
                try encoded.write(to: url)
                logger.info("✅ Exported folder '\(folder.name)' with \(folderSnippets.count) snippets")
            } catch {
                logger.error("❌ Export failed: \(error.localizedDescription)")
                showExportError(error)
            }
        }
    }
    
    private func showExportError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = "Could not export folder: \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    // MARK: - Duplicate Alert
    
    private func showDuplicateAlert(existing: Snippet, newName: String, folderId: UUID?) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Duplicate Snippet"
        
        // Get folder name
        let folderName: String
        if let folderId = folderId, let folder = folders.first(where: { $0.id == folderId }) {
            folderName = folder.name
        } else {
            folderName = "No Folder"
        }
        
        // Build informative message
        var message = "This content already exists in \"\(folderName)\".\n\n"
        message += "Existing snippet: \"\(existing.name)\"\n"
        message += "New name: \"\(newName)\"\n\n"
        message += "The clip has been removed from your history."
        
        alert.informativeText = message
        alert.icon = NSImage(systemSymbolName: "doc.on.doc.fill", accessibilityDescription: "Duplicate")
        
        // Add buttons
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Replace Existing")
        
        // Run modal
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            // User chose to replace - update the existing snippet with new name
            var updatedSnippet = existing
            updatedSnippet.name = newName
            updateSnippet(updatedSnippet)
            
            logger.info("✏️ Replaced existing snippet with new name: \(newName)")
            #if DEBUG
            logger.debug("✅ User chose to replace existing snippet")
            #endif
        } else {
            #if DEBUG
            logger.debug("ℹ️ User chose to keep existing snippet")
            #endif
        }
    }
}

