//
//  ClipboardManager+Folders.swift
//  SimpleCP
//
//  Folder management and search extension for ClipboardManager
//

import Foundation

extension ClipboardManager {
    // MARK: - Folder Management

    func createFolder(name: String, icon: String = "📁") -> UUID {
        // DEBUG: Log all folder creation with stack trace
        logger.warning("🔴 CREATE FOLDER CALLED: '\(name)'")
        print("🔴🔴🔴 CREATE FOLDER CALLED: '\(name)'")
        print("Stack trace:")
        Thread.callStackSymbols.prefix(10).forEach { print($0) }

        // Insert new folders at the top (order 0)
        let folder = SnippetFolder(name: name, icon: icon, order: 0)

        // Increment order of all existing folders
        for index in folders.indices {
            folders[index].order += 1
        }

        // Insert new folder at the beginning
        folders.insert(folder, at: 0)
        
        // Explicitly notify observers that the folders array changed
        objectWillChange.send()
        
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
        print("🟢 toggleFolderExpansion called for folder ID: \(folderId)")
        print("🟢 Current folder count: \(folders.count)")
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            print("🟢 Found folder at index \(index): '\(folders[index].name)'")
            folders[index].toggleExpanded()
            saveFolders()
            print("🟢 After toggle, folder count: \(folders.count)")
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
