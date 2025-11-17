import Foundation

// App-wide constants
struct Constants {
    // API Configuration
    static let apiBaseURL = "http://127.0.0.1:8000"
    static let apiTimeout: TimeInterval = 30

    // UI Constants - Menu Bar App Dimensions
    static let windowMinWidth: CGFloat = 320
    static let windowMinHeight: CGFloat = 400
    static let defaultWindowWidth: CGFloat = 350
    static let defaultWindowHeight: CGFloat = 500

    // History Settings
    static let maxHistoryDisplay = 10
    static let historyFolderSize = 10

    // Snippet Settings
    static let defaultSnippetFolder = "General"
    static let maxSnippetNameLength = 100

    // Search
    static let minSearchQueryLength = 2
    static let searchDebounceDelay: TimeInterval = 0.3

    // Refresh
    static let autoRefreshInterval: TimeInterval = 5.0

    // Content Display
    static let previewMaxLength = 200
    static let previewMaxLines = 3
}
