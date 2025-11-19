import Foundation

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
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

    init(
        id: UUID = UUID(),
        clipId: String,
        content: String,
        contentType: String = "text",
        timestamp: Date = Date(),
        displayString: String? = nil,
        sourceApp: String? = nil,
        itemType: String = "history",
        hasName: Bool = false,
        snippetName: String? = nil,
        folderPath: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.clipId = clipId
        self.content = content
        self.contentType = contentType
        self.timestamp = timestamp
        self.displayString = displayString ?? String(content.prefix(100))
        self.sourceApp = sourceApp
        self.itemType = itemType
        self.hasName = hasName
        self.snippetName = snippetName
        self.folderPath = folderPath
        self.tags = tags
    }

    // Coding keys to match Python backend JSON format
    enum CodingKeys: String, CodingKey {
        case id
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

    // Custom date decoding/encoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        clipId = try container.decode(String.self, forKey: .clipId)
        content = try container.decode(String.self, forKey: .content)
        contentType = try container.decodeIfPresent(String.self, forKey: .contentType) ?? "text"

        // Handle timestamp as either ISO8601 string or double
        if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
            let formatter = ISO8601DateFormatter()
            timestamp = formatter.date(from: timestampString) ?? Date()
        } else if let timestampDouble = try? container.decode(Double.self, forKey: .timestamp) {
            timestamp = Date(timeIntervalSince1970: timestampDouble)
        } else {
            timestamp = Date()
        }

        displayString = try container.decodeIfPresent(String.self, forKey: .displayString) ?? String(content.prefix(100))
        sourceApp = try container.decodeIfPresent(String.self, forKey: .sourceApp)
        itemType = try container.decodeIfPresent(String.self, forKey: .itemType) ?? "history"
        hasName = try container.decodeIfPresent(Bool.self, forKey: .hasName) ?? false
        snippetName = try container.decodeIfPresent(String.self, forKey: .snippetName)
        folderPath = try container.decodeIfPresent(String.self, forKey: .folderPath)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

// Sample data for previews
extension ClipboardItem {
    static let sample = ClipboardItem(
        clipId: "sample-1",
        content: "This is a sample clipboard item for preview purposes",
        timestamp: Date()
    )

    static let samples: [ClipboardItem] = [
        ClipboardItem(clipId: "1", content: "Latest clipboard item with some text content", timestamp: Date()),
        ClipboardItem(clipId: "2", content: "Second most recent clipboard item", timestamp: Date().addingTimeInterval(-60)),
        ClipboardItem(clipId: "3", content: "Third clipboard item from a few minutes ago", timestamp: Date().addingTimeInterval(-180)),
        ClipboardItem(clipId: "4", content: "Fourth item in the history", timestamp: Date().addingTimeInterval(-300)),
        ClipboardItem(clipId: "5", content: "Fifth clipboard entry", timestamp: Date().addingTimeInterval(-600))
    ]

    static let sampleSnippet = ClipboardItem(
        clipId: "snippet-1",
        content: "Dear [Name],\n\nThank you for reaching out...",
        itemType: "snippet",
        hasName: true,
        snippetName: "Email Template - Thank You",
        folderPath: "Email Templates",
        tags: ["email", "template"]
    )
}
