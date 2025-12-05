//
//  ClipboardManager+Snippets.swift
//  SimpleCP
//
//  Snippet management extension for ClipboardManager
//

import Foundation

extension ClipboardManager {
    // MARK: - Snippet Management

    func saveAsSnippet(name: String, content: String, folderId: UUID?, tags: [String] = []) {
        let snippet = Snippet(
            name: name,
            content: content,
            tags: tags,
            folderId: folderId
        )
        snippets.append(snippet)
        saveSnippets()
        logger.info("💾 Saved snippet: \(name)")

        // Sync with backend
        Task {
            do {
                // Get folder name from folderId
                let folderName: String
                if let folderId = folderId, let folder = folders.first(where: { $0.id == folderId }) {
                    folderName = folder.name
                } else {
                    folderName = "General"
                }

                try await APIClient.shared.createSnippet(
                    name: name,
                    content: content,
                    folder: folderName,
                    tags: tags
                )
                await MainActor.run {
                    logger.info("💾 Snippet synced with backend: \(name)")
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
}
