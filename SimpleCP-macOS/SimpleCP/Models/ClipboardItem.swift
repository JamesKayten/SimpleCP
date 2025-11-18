import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: String
    let content: String
    let preview: String
    let name: String?
    let tags: [String]
    let folder: String?
    let timestamp: String
    let wordCount: Int
    let charCount: Int
    let lineCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "clip_id"
        case content, preview, name, tags, folder, timestamp
        case wordCount = "word_count"
        case charCount = "char_count"
        case lineCount = "line_count"
    }
}

struct HistoryFolder: Identifiable, Codable {
    let id = UUID()
    let name: String
    let startIndex: Int
    let endIndex: Int
    let count: Int
    let items: [ClipboardItem]

    enum CodingKeys: String, CodingKey {
        case name, count, items
        case startIndex = "start_index"
        case endIndex = "end_index"
    }
}

struct SnippetFolder: Identifiable, Codable {
    let id = UUID()
    let folderName: String
    let snippets: [ClipboardItem]

    enum CodingKeys: String, CodingKey {
        case folderName = "folder_name"
        case snippets
    }
}

struct SearchResults: Codable {
    let history: [ClipboardItem]
    let snippets: [ClipboardItem]
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}