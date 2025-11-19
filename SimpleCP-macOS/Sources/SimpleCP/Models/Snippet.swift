//
//  Snippet.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import Foundation

struct Snippet: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var content: String
    var tags: [String]
    let createdAt: Date
    var modifiedAt: Date
    var folderId: UUID?
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        name: String,
        content: String,
        tags: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        folderId: UUID? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.folderId = folderId
        self.isFavorite = isFavorite
    }

    var preview: String {
        let maxLength = 80
        if content.count > maxLength {
            return String(content.prefix(maxLength)) + "..."
        }
        return content
    }

    mutating func update(content: String) {
        self.content = content
        self.modifiedAt = Date()
    }

    mutating func rename(to newName: String) {
        self.name = newName
        self.modifiedAt = Date()
    }

    mutating func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
            modifiedAt = Date()
        }
    }

    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        modifiedAt = Date()
    }
}
