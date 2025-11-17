import Foundation

// Request/Response models for API communication

// MARK: - Request Models

struct CreateSnippetRequest: Codable {
    let content: String
    let snippetName: String
    let folderPath: String
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case content
        case snippetName = "snippet_name"
        case folderPath = "folder_path"
        case tags
    }
}

struct UpdateSnippetRequest: Codable {
    let snippetName: String?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case snippetName = "snippet_name"
        case tags
    }
}

struct CreateFolderRequest: Codable {
    let name: String
}

struct RenameFolderRequest: Codable {
    let oldName: String
    let newName: String

    enum CodingKeys: String, CodingKey {
        case oldName = "old_name"
        case newName = "new_name"
    }
}

struct DeleteFolderRequest: Codable {
    let name: String
}

struct CopyToClipboardRequest: Codable {
    let itemId: String

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
    }
}

struct SearchRequest: Codable {
    let query: String
}

// MARK: - Response Models

struct HistoryResponse: Codable {
    let history: [ClipboardItem]
}

struct SnippetsResponse: Codable {
    let snippets: [String: [ClipboardItem]]
}

struct HistoryFolder: Identifiable, Codable {
    let id = UUID()
    let name: String
    let itemCount: Int
    let startIndex: Int
    let endIndex: Int

    enum CodingKeys: String, CodingKey {
        case name
        case itemCount = "item_count"
        case startIndex = "start_index"
        case endIndex = "end_index"
    }
}

struct HistoryFoldersResponse: Codable {
    let folders: [HistoryFolder]
}

struct SearchResults: Codable {
    let historyMatches: [ClipboardItem]
    let snippetMatches: [ClipboardItem]

    enum CodingKeys: String, CodingKey {
        case historyMatches = "history_matches"
        case snippetMatches = "snippet_matches"
    }
}

struct HealthStatus: Codable {
    let status: String
    let historyCount: Int
    let snippetFolders: Int

    enum CodingKeys: String, CodingKey {
        case status
        case historyCount = "history_count"
        case snippetFolders = "snippet_folders"
    }
}

struct MessageResponse: Codable {
    let message: String
}

struct ErrorResponse: Codable {
    let detail: String
}
