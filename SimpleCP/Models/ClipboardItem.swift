import Foundation

// Swift equivalent of Python ClipboardItem model
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id = UUID()
    let clipId: String
    let content: String
    let contentType: String
    let timestamp: Date
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
        case contentType = "content_type"
        case timestamp
        case displayString = "display_string"
        case sourceApp = "source_app"
        case itemType = "item_type"
        case hasName = "has_name"
        case snippetName = "snippet_name"
        case folderPath = "folder_path"
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        clipId = try container.decode(String.self, forKey: .clipId)
        content = try container.decode(String.self, forKey: .content)
        contentType = try container.decode(String.self, forKey: .contentType)

        // Handle timestamp as ISO8601 string
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        timestamp = formatter.date(from: timestampString) ?? Date()

        displayString = try container.decode(String.self, forKey: .displayString)
        sourceApp = try container.decodeIfPresent(String.self, forKey: .sourceApp)
        itemType = try container.decode(String.self, forKey: .itemType)
        hasName = try container.decode(Bool.self, forKey: .hasName)
        snippetName = try container.decodeIfPresent(String.self, forKey: .snippetName)
        folderPath = try container.decodeIfPresent(String.self, forKey: .folderPath)
        tags = try container.decode([String].self, forKey: .tags)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clipId, forKey: .clipId)
        try container.encode(content, forKey: .content)
        try container.encode(contentType, forKey: .contentType)

        // Encode timestamp as ISO8601 string
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: timestamp), forKey: .timestamp)

        try container.encode(displayString, forKey: .displayString)
        try container.encodeIfPresent(sourceApp, forKey: .sourceApp)
        try container.encode(itemType, forKey: .itemType)
        try container.encode(hasName, forKey: .hasName)
        try container.encodeIfPresent(snippetName, forKey: .snippetName)
        try container.encodeIfPresent(folderPath, forKey: .folderPath)
        try container.encode(tags, forKey: .tags)
    }

    // Manual initializer for creating items
    init(clipId: String, content: String, contentType: String, timestamp: Date = Date(),
         displayString: String, sourceApp: String? = nil, itemType: String,
         hasName: Bool = false, snippetName: String? = nil, folderPath: String? = nil,
         tags: [String] = []) {
        self.clipId = clipId
        self.content = content
        self.contentType = contentType
        self.timestamp = timestamp
        self.displayString = displayString
        self.sourceApp = sourceApp
        self.itemType = itemType
        self.hasName = hasName
        self.snippetName = snippetName
        self.folderPath = folderPath
        self.tags = tags
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.clipId == rhs.clipId
    }
}
