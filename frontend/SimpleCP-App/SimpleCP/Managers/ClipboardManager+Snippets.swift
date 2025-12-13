//
//  ClipboardManager+Snippets.swift
//  SimpleCP
//
//  Snippet management extension for ClipboardManager

import Foundation
import AppKit

extension ClipboardManager {
    // MARK: - Snippet Management

    func saveAsSnippet(name: String, content: String, folderId: UUID?, tags: [String] = []) {
        // Check for duplicates in the same folder
        if let existing = snippets.first(where: { $0.content == content && $0.folderId == folderId }) {
            logger.warning("⚠️ Duplicate snippet detected: '\(existing.name)' in same folder")
            DispatchQueue.main.async { [weak self] in
                self?.showDuplicateAlert(existing: existing, newName: name, folderId: folderId)
            }
            if let clipToRemove = clipHistory.first(where: { $0.content == content }) {
                removeFromHistory(item: clipToRemove)
            }
            return
        }

        let clipToRemove: ClipItem? = clipHistory.first(where: { $0.content == content })
        let snippet = Snippet(name: name, content: content, tags: tags, folderId: folderId)
        snippets.append(snippet)
        saveSnippets()
        logger.info("💾 Saved snippet: \(name)")

        if let clipToRemove = clipToRemove {
            removeFromHistory(item: clipToRemove)
            logger.info("🗑️ Removed clip from history (now saved as snippet)")
        }

        // Sync with backend
        Task {
            do {
                let folderName = folderId.flatMap { id in folders.first { $0.id == id }?.name } ?? "General"
                try await APIClient.shared.createSnippet(
                    name: name, content: content, folder: folderName, tags: tags, clipId: nil
                )
                await MainActor.run { logger.info("💾 Snippet synced with backend: \(name)") }
            } catch APIError.httpError(let statusCode, let message) where statusCode >= 500 {
                await MainActor.run { logger.error("❌ Backend server error (HTTP \(statusCode)): \(message)") }
            } catch APIError.networkError(let error) {
                await MainActor.run { logger.error("❌ Network error syncing snippet: \(error.localizedDescription)") }
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
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[index] = snippet
        saveSnippets()
        logger.info("✏️ Updated snippet: \(snippet.name)")

        Task {
            do {
                let folderName = snippet.folderId.flatMap { id in folders.first { $0.id == id }?.name } ?? "General"
                let clipId = String(snippet.id.uuidString.replacingOccurrences(of: "-", with: "").prefix(16).lowercased())
                try await APIClient.shared.updateSnippet(
                    folderName: folderName, clipId: clipId, content: snippet.content, name: snippet.name, tags: snippet.tags
                )
                await MainActor.run { logger.info("✏️ Snippet update synced with backend: \(snippet.name)") }
            } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
                await MainActor.run { logger.info("ℹ️ Snippet was not on backend (local-only snippet)") }
            } catch {
                await MainActor.run { logger.warning("⚠️ Failed to sync snippet update: \(error.localizedDescription)") }
            }
        }
    }

    func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        saveSnippets()
        logger.info("🗑️ Deleted snippet: \(snippet.name)")

        Task {
            do {
                let folderName = snippet.folderId.flatMap { id in folders.first { $0.id == id }?.name } ?? "General"
                let clipId = String(snippet.id.uuidString.replacingOccurrences(of: "-", with: "").prefix(16).lowercased())
                try await APIClient.shared.deleteSnippet(folderName: folderName, clipId: clipId)
                await MainActor.run { logger.info("🗑️ Snippet deletion synced with backend: \(snippet.name)") }
            } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
                await MainActor.run { logger.info("ℹ️ Snippet was not on backend (already deleted or never synced)") }
            } catch {
                await MainActor.run { logger.warning("⚠️ Failed to sync snippet deletion: \(error.localizedDescription)") }
            }
        }
    }

    func getSnippets(for folderId: UUID) -> [Snippet] {
        snippets.filter { $0.folderId == folderId }
    }

    func suggestSnippetName(for content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? ""
        return firstLine.isEmpty ? "Untitled Snippet" : String(firstLine.prefix(50))
    }

    // MARK: - Duplicate Alert

    private func showDuplicateAlert(existing: Snippet, newName: String, folderId: UUID?) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Duplicate Snippet"

        let folderName = folderId.flatMap { id in folders.first { $0.id == id }?.name } ?? "No Folder"
        alert.informativeText = """
            This content already exists in "\(folderName)".

            Existing snippet: "\(existing.name)"
            New name: "\(newName)"

            The clip has been removed from your history.
            """
        alert.icon = NSImage(systemSymbolName: "doc.on.doc.fill", accessibilityDescription: "Duplicate")
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Replace Existing")

        if alert.runModal() == .alertSecondButtonReturn {
            var updatedSnippet = existing
            updatedSnippet.name = newName
            updateSnippet(updatedSnippet)
            logger.info("✏️ Replaced existing snippet with new name: \(newName)")
        }
    }
}
