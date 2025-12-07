//
//  SnippetFolder.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import Foundation

struct SnippetFolder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var isExpanded: Bool
    var order: Int
    let createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "📁",
        isExpanded: Bool = false,
        order: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isExpanded = isExpanded
        self.order = order
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    mutating func toggleExpanded() {
        isExpanded.toggle()
        modifiedAt = Date()
    }

    mutating func rename(to newName: String) {
        self.name = newName
        modifiedAt = Date()
    }

    mutating func changeIcon(to newIcon: String) {
        self.icon = newIcon
        modifiedAt = Date()
    }

    static func defaultFolders() -> [SnippetFolder] {
        [
            SnippetFolder(name: "Email Templates", icon: "📧", order: 0),
            SnippetFolder(name: "Code Snippets", icon: "💻", order: 1),
            SnippetFolder(name: "Common Text", icon: "📝", order: 2)
        ]
    }
}
