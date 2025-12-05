//
//  ClipItem.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import Foundation

struct ClipItem: Identifiable, Codable, Hashable {
    let id: UUID
    let content: String
    let timestamp: Date
    let contentType: ContentType

    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), contentType: ContentType = .text) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.contentType = contentType
    }

    enum ContentType: String, Codable {
        case text
        case code
        case url
        case email
        case unknown
    }

    var preview: String {
        let maxLength = 100
        if content.count > maxLength {
            return String(content.prefix(maxLength)) + "..."
        }
        return content
    }

    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
