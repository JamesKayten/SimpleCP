//
//  ClipboardManager+Persistence.swift
//  SimpleCP
//
//  Persistence extension for ClipboardManager
//

import Foundation
import AppKit

extension ClipboardManager {
    // MARK: - Persistence

    func saveHistory() {
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

    func saveSnippets() {
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

    func saveFolders() {
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

    func loadData() {
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
}
