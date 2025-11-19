import Foundation

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
    let content: String?
    let snippetName: String?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case content
        case snippetName = "snippet_name"
        case tags
    }
}

struct CreateFolderRequest: Codable {
    let name: String
}

struct RenameFolderRequest: Codable {
    let newName: String

    enum CodingKeys: String, CodingKey {
        case newName = "new_name"
    }
}

// MARK: - Response Models

struct SearchResults: Codable {
    let historyMatches: [ClipboardItem]
    let snippetMatches: [String: [ClipboardItem]]

    enum CodingKeys: String, CodingKey {
        case historyMatches = "history_matches"
        case snippetMatches = "snippet_matches"
    }
}

struct HealthStatus: Codable {
    let status: String
    let version: String?
    let uptime: Double?
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}

struct ErrorResponse: Codable {
    let error: String
    let details: String?
}
