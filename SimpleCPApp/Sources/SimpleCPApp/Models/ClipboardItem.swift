//
//  ClipboardItem.swift
//  SimpleCPApp
//
//  Model matching Python backend ClipboardItem
//

import Foundation

/// Represents a clipboard item - matches Python ClipboardItemResponse
struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    let clipId: String
    let content: String
    let timestamp: String
    let contentType: String
    let displayString: String
    let sourceApp: String?
    let itemType: String
    let hasName: Bool
    let snippetName: String?
    let folderPath: String?
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case clipId = "clip_id"
        case content
        case timestamp
        case contentType = "content_type"
        case displayString = "display_string"
        case sourceApp = "source_app"
        case itemType = "item_type"
        case hasName = "has_name"
        case snippetName = "snippet_name"
        case folderPath = "folder_path"
        case tags
    }

    /// Parse timestamp to Date
    var timestampDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timestamp)
    }

    /// Format timestamp for display
    var formattedTimestamp: String {
        guard let date = timestampDate else { return timestamp }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Truncated content for list display
    var truncatedContent: String {
        if displayString.count > 100 {
            return String(displayString.prefix(100)) + "..."
        }
        return displayString
    }

    /// Icon for content type
    var typeIcon: String {
        switch contentType {
        case "code": return "chevron.left.forwardslash.chevron.right"
        case "url": return "link"
        case "email": return "envelope"
        default: return "doc.text"
        }
    }
}

/// History folder with auto-generated ranges (11-20, 21-30, etc.)
struct HistoryFolder: Identifiable, Codable {
    let id = UUID()
    let name: String
    let startIndex: Int
    let endIndex: Int
    let count: Int
    let items: [ClipboardItem]

    enum CodingKeys: String, CodingKey {
        case name
        case startIndex = "start_index"
        case endIndex = "end_index"
        case count
        case items
    }
}

/// Snippet folder
struct SnippetFolder: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var items: [ClipboardItem]
    var isExpanded: Bool = false

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: SnippetFolder, rhs: SnippetFolder) -> Bool {
        lhs.name == rhs.name
    }
}
