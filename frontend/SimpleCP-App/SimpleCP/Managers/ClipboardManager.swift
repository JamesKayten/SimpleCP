//
//  ClipboardManager.swift
//  SimpleCP
//
//  Extensions: +BackendSync, +Folders, +Persistence, +Snippets
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

    /// Tracks folder names that were deleted locally to prevent re-sync from backend
    var locallyDeletedFolderNames: Set<String> = []

    var timer: Timer?
    var lastChangeCount: Int = 0
    let maxHistorySize: Int = 50
    let userDefaults = UserDefaults.standard
    let logger = Logger(subsystem: "com.simplecp.app", category: "clipboard")
    var ignoreNextChange: Bool = false

    let historyKey = "clipboardHistory"
    let snippetsKey = "savedSnippets"
    let foldersKey = "snippetFolders"

    // MARK: - Flyout Delay Settings

    var clipPreviewDelay: TimeInterval {
        get { userDefaults.double(forKey: "clipPreviewDelay") == 0 ? 0.7 : userDefaults.double(forKey: "clipPreviewDelay") }
        set { userDefaults.set(newValue, forKey: "clipPreviewDelay") }
    }

    var clipGroupFlyoutDelay: TimeInterval {
        get { userDefaults.double(forKey: "clipGroupFlyoutDelay") == 0 ? 0.5 : userDefaults.double(forKey: "clipGroupFlyoutDelay") }
        set { userDefaults.set(newValue, forKey: "clipGroupFlyoutDelay") }
    }

    var folderFlyoutDelay: TimeInterval {
        get { let value = userDefaults.double(forKey: "folderFlyoutDelay"); return value == 0 ? 1.0 : value }
        set { userDefaults.set(newValue, forKey: "folderFlyoutDelay") }
    }

    init() {
        loadData()
        startMonitoring()
        Task { await waitForBackendAndSync() }
    }

    // MARK: - Clipboard Monitoring

    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        if let timer = timer { RunLoop.main.add(timer, forMode: .common) }
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

        if ignoreNextChange {
            ignoreNextChange = false
            logger.debug("📋 Ignoring programmatic clipboard change")
            return
        }

        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            guard shouldStoreContent(content) else {
                logger.info("📋 Skipped storing clipboard content (filtered)")
                return
            }
            currentClipboard = content
            addToHistory(content: content)
            logger.debug("📋 New clipboard item: \(self.sanitizeForLogging(content))")
        }
    }

    // MARK: - History Management

    func addToHistory(content: String) {
        if let existingIndex = clipHistory.firstIndex(where: { $0.content == content }) {
            let item = clipHistory.remove(at: existingIndex)
            clipHistory.insert(item, at: 0)
            logger.debug("📋 Moved existing clip to top")
        } else {
            let contentType = detectContentType(content)
            let newItem = ClipItem(content: content, contentType: contentType)
            clipHistory.insert(newItem, at: 0)

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
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { self.copyToClipboard(content) }
            return
        }

        logger.info("🔵 COPY REQUESTED: \(content.count) chars")
        ignoreNextChange = true

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(content, forType: .string)

        if success {
            lastChangeCount = pasteboard.changeCount
            currentClipboard = content

            if let readBack = pasteboard.string(forType: .string), readBack == content {
                logger.info("✅ COPIED TO CLIPBOARD (\(content.count) chars)")
            } else {
                logger.error("❌ Clipboard verification failed")
                ignoreNextChange = false
            }
        } else {
            logger.error("❌ Failed to set clipboard content")
            ignoreNextChange = false
        }
    }

    func detectContentType(_ content: String) -> ClipItem.ContentType {
        if content.hasPrefix("http://") || content.hasPrefix("https://") { return .url }
        else if content.contains("@") && content.contains(".") && !content.contains(" ") { return .email }
        else if content.contains("{") || content.contains("func ") || content.contains("import ") { return .code }
        return .text
    }

    deinit { stopMonitoring() }
}
