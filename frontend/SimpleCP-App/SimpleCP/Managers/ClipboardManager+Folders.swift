//
//  ClipboardManager+Folders.swift
//  SimpleCP
//
//  Folder management and search extension for ClipboardManager
//

import Foundation
import AppKit
import UniformTypeIdentifiers

extension ClipboardManager {
    // MARK: - Folder Management

    func createFolder(name: String, icon: String = "📁") -> UUID {
        logger.info("📁 Creating folder: '\(name)'")

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
            } catch APIError.httpError(let statusCode, _) where statusCode == 409 {
                // 409 conflict means folder already exists on backend - that's fine!
                await MainActor.run {
                    logger.info("ℹ️ Folder '\(name)' already exists on backend (local folder created successfully)")
                }
            } catch {
                await MainActor.run {
                    logger.error("❌ Failed to sync folder creation with backend: \(error.localizedDescription)")
                    lastError = .apiError("Failed to sync folder creation: \(error.localizedDescription)")
                    showError = true
                }
            }
        }
        
        // Return the ID of the newly created folder
        return folder.id
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
                    } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
                        // 404 means old folder wasn't on backend - that's okay, local rename succeeded
                        await MainActor.run {
                            logger.info("ℹ️ Old folder was not on backend (local-only folder)")
                        }
                    } catch APIError.httpError(let statusCode, let message) where statusCode == 409 {
                        // 409 conflict means new name already exists on backend
                        await MainActor.run {
                            logger.warning("⚠️ Folder name '\(newName)' already exists on backend: \(message)")
                            // Keep local change - user intended this rename
                        }
                    } catch {
                        await MainActor.run {
                            logger.warning("⚠️ Failed to sync folder rename with backend: \(error.localizedDescription)")
                            // Don't revert or show error - local rename is what user wanted
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

        // Track this folder as locally deleted to prevent re-sync from backend
        locallyDeletedFolderNames.insert(folder.name)

        // Remove snippets in this folder
        snippets.removeAll { $0.folderId == folder.id }
        folders.removeAll { $0.id == folder.id }
        saveFolders()
        saveSnippets()

        // Sync with backend
        let folderName = folder.name
        Task {
            do {
                try await APIClient.shared.deleteFolder(name: folderName)
                await MainActor.run {
                    // Successfully deleted from backend - can remove from deleted tracking
                    self.locallyDeletedFolderNames.remove(folderName)
                    logger.info("🗑️ Deleted folder '\(folderName)' and \(snippetCount) snippets (synced with backend)")
                }
            } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
                // 404 means folder wasn't on backend - that's fine, it's deleted locally
                await MainActor.run {
                    self.locallyDeletedFolderNames.remove(folderName)
                    logger.info("ℹ️ Folder '\(folderName)' was not on backend (local deletion successful)")
                }
            } catch {
                await MainActor.run {
                    // Keep in locallyDeletedFolderNames to prevent re-sync
                    logger.warning("⚠️ Failed to sync folder deletion with backend: \(error.localizedDescription)")
                }
            }
        }
    }

    func toggleFolderExpansion(_ folderId: UUID) {
        guard let index = folders.firstIndex(where: { $0.id == folderId }) else {
            logger.warning("⚠️ Attempted to toggle non-existent folder: \(folderId)")
            return
        }
        
        folders[index].toggleExpanded()
        saveFolders()
        logger.debug("🔄 Toggled folder '\(self.folders[index].name)': expanded=\(self.folders[index].isExpanded)")
    }
    
    // MARK: - Export
    
    func exportFolder(_ folder: SnippetFolder) {
        let folderSnippets = getSnippets(for: folder.id)
        
        // Create JSON export data
        let exportData: [String: Any] = [
            "folder": [
                "name": folder.name,
                "icon": folder.icon,
                "created": ISO8601DateFormatter().string(from: folder.createdAt)
            ],
            "snippets": folderSnippets.map { snippet in
                [
                    "name": snippet.name,
                    "content": snippet.content,
                    "tags": snippet.tags,
                    "created": ISO8601DateFormatter().string(from: snippet.createdAt),
                    "isFavorite": snippet.isFavorite
                ]
            }
        ]
        
        // Convert to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            logger.error("Failed to create JSON export for folder '\(folder.name)'")
            lastError = .exportFailure("Failed to create export data")
            showError = true
            return
        }
        
        // Show save panel
        let savePanel = NSSavePanel()
        savePanel.title = "Export Folder"
        savePanel.message = "Choose where to save the folder export"
        savePanel.nameFieldStringValue = "\(folder.name).json"
        savePanel.allowedContentTypes = [.json]
        savePanel.canCreateDirectories = true
        
        savePanel.begin { [weak self] response in
            guard let self else { return }
            if response == .OK, let url = savePanel.url {
                do {
                    try jsonString.write(to: url, atomically: true, encoding: .utf8)
                    self.logger.info("📤 Exported folder '\(folder.name)' to \(url.path)")
                } catch {
                    self.logger.error("Failed to save export: \(error.localizedDescription)")
                    self.lastError = .exportFailure("Failed to save export: \(error.localizedDescription)")
                    self.showError = true
                }
            }
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
}
