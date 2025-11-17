//
//  APIModels.swift
//  SimpleCPApp
//
//  Request and response models for Python backend API
//

import Foundation

// MARK: - API Configuration
struct APIConfig: Codable {
    let apiBaseURL: String
    let host: String
    let port: Int
    let apiVersion: String
    let endpoints: APIEndpoints

    enum CodingKeys: String, CodingKey {
        case apiBaseURL = "api_base_url"
        case host
        case port
        case apiVersion = "api_version"
        case endpoints
    }
}

struct APIEndpoints: Codable {
    let history: String
    let snippets: String
    let search: String
}

// MARK: - Health Check
struct HealthResponse: Codable {
    let status: String
    let stats: Stats
}

struct Stats: Codable {
    let historyCount: Int
    let snippetCount: Int
    let folderCount: Int
    let maxHistory: Int

    enum CodingKeys: String, CodingKey {
        case historyCount = "history_count"
        case snippetCount = "snippet_count"
        case folderCount = "folder_count"
        case maxHistory = "max_history"
    }
}

// MARK: - Search Results
struct SearchResults: Codable {
    let history: [ClipboardItem]
    let snippets: [ClipboardItem]
}

// MARK: - Snippet Requests
struct CreateSnippetRequest: Codable {
    let clipId: String?
    let content: String?
    let name: String
    let folder: String
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case clipId = "clip_id"
        case content
        case name
        case folder
        case tags
    }
}

struct UpdateSnippetRequest: Codable {
    let content: String?
    let name: String?
    let tags: [String]?
}

struct MoveSnippetRequest: Codable {
    let toFolder: String

    enum CodingKeys: String, CodingKey {
        case toFolder = "to_folder"
    }
}

// MARK: - Folder Requests
struct CreateFolderRequest: Codable {
    let folderName: String

    enum CodingKeys: String, CodingKey {
        case folderName = "folder_name"
    }
}

struct RenameFolderRequest: Codable {
    let newName: String

    enum CodingKeys: String, CodingKey {
        case newName = "new_name"
    }
}

// MARK: - Generic Responses
struct SuccessResponse: Codable {
    let success: Bool
    let message: String?
}

struct ErrorResponse: Codable {
    let error: String
    let detail: String?
}

// MARK: - Copy Request
struct CopyRequest: Codable {
    let clipId: String

    enum CodingKeys: String, CodingKey {
        case clipId = "clip_id"
    }
}
