//
//  ClipboardManager+Folders.swift
//  SimpleCP
//
//  Folder management extension for ClipboardManager
//

import Foundation

extension ClipboardManager {
    // MARK: - Folder Management

    @discardableResult
    func createFolder(name: String) -> SnippetFolder {
        // Find the highest order value
        let maxOrder = folders.map { $0.order }.max() ?? -1
        
        let newFolder = SnippetFolder(
            name: name,
            icon: "📁",
            order: maxOrder + 1
        )
        
        folders.append(newFolder)
        saveFolders()
        
        logger.info("📁 Created folder: \(name)")
        
        // Sync with backend
        Task {
            do {
                try await APIClient.shared.createFolder(name: name)
                logger.info("✅ Folder synced with backend: \(name)")
            } catch APIError.httpError(let statusCode, _) where statusCode == 409 {
                // 409 conflict means folder already exists on backend - that's fine
                logger.debug("ℹ️ Folder '\(name)' already exists on backend")
            } catch {
                logger.warning("⚠️ Failed to sync folder creation with backend: \(error.localizedDescription)")
                // Keep local folder even if backend sync fails
            }
        }
        
        return newFolder
    }

    func renameFolder(_ folder: SnippetFolder, newName: String) {
        guard let index = folders.firstIndex(where: { $0.id == folder.id }) else {
            logger.warning("⚠️ Attempted to rename non-existent folder")
            return
        }
        
        let oldName = folders[index].name
        folders[index].name = newName
        folders[index].modifiedAt = Date()
        saveFolders()
        
        logger.info("✏️ Renamed folder: '\(oldName)' → '\(newName)'")
        
        // Sync with backend
        Task {
            do {
                try await APIClient.shared.renameFolder(oldName: oldName, newName: newName)
                logger.info("✅ Folder rename synced with backend")
            } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
                // 404 means folder wasn't on backend - that's okay
                logger.info("ℹ️ Folder was not on backend (local-only folder)")
            } catch {
                logger.warning("⚠️ Failed to sync folder rename with backend: \(error.localizedDescription)")
                // Keep local rename even if backend sync fails
            }
        }
    }

    func deleteFolder(_ folder: SnippetFolder) {
        // Remove the folder
        folders.removeAll { $0.id == folder.id }
        
        // Remove all snippets in this folder
        let snippetsToDelete = snippets.filter { $0.folderId == folder.id }
        snippets.removeAll { $0.folderId == folder.id }
        
        saveFolders()
        saveSnippets()
        
        logger.info("🗑️ Deleted folder: \(folder.name) (\(snippetsToDelete.count) snippets removed)")
        
        // Sync with backend
        Task {
            do {
                try await APIClient.shared.deleteFolder(name: folder.name)
                logger.info("✅ Folder deletion synced with backend")
            } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
                // 404 means folder wasn't on backend - that's fine
                logger.info("ℹ️ Folder was not on backend (already deleted or never synced)")
            } catch {
                logger.warning("⚠️ Failed to sync folder deletion with backend: \(error.localizedDescription)")
                // Don't show error - folder is already deleted locally
            }
        }
    }
}
