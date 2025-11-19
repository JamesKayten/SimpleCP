import Foundation

struct SnippetFolder: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    var isExpanded: Bool
    var snippets: [ClipboardItem]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        isExpanded: Bool = false,
        snippets: [ClipboardItem] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isExpanded = isExpanded
        self.snippets = snippets
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case isExpanded = "is_expanded"
        case snippets
    }
}

// Sample data for previews
extension SnippetFolder {
    static let sample = SnippetFolder(
        name: "Email Templates",
        icon: "envelope.fill",
        isExpanded: true,
        snippets: [
            ClipboardItem(
                clipId: "email-1",
                content: "Dear [Name],\n\nThank you for your inquiry...",
                itemType: "snippet",
                hasName: true,
                snippetName: "Meeting Request",
                folderPath: "Email Templates"
            ),
            ClipboardItem(
                clipId: "email-2",
                content: "Hi [Name],\n\nFollowing up on our conversation...",
                itemType: "snippet",
                hasName: true,
                snippetName: "Follow Up",
                folderPath: "Email Templates"
            ),
            ClipboardItem(
                clipId: "email-3",
                content: "Dear [Name],\n\nThank you for your time...",
                itemType: "snippet",
                hasName: true,
                snippetName: "Thank You",
                folderPath: "Email Templates"
            )
        ]
    )

    static let samples: [SnippetFolder] = [
        SnippetFolder(
            name: "Email Templates",
            icon: "envelope.fill",
            isExpanded: true,
            snippets: [
                ClipboardItem(
                    clipId: "email-1",
                    content: "Dear [Name],\n\nI hope this email finds you well...",
                    itemType: "snippet",
                    hasName: true,
                    snippetName: "Meeting Request",
                    folderPath: "Email Templates"
                ),
                ClipboardItem(
                    clipId: "email-2",
                    content: "Hi [Name],\n\nFollowing up on our previous discussion...",
                    itemType: "snippet",
                    hasName: true,
                    snippetName: "Follow Up",
                    folderPath: "Email Templates"
                )
            ]
        ),
        SnippetFolder(
            name: "Code Snippets",
            icon: "chevron.left.forwardslash.chevron.right",
            isExpanded: false,
            snippets: [
                ClipboardItem(
                    clipId: "code-1",
                    content: "if __name__ == \"__main__\":\n    main()",
                    itemType: "snippet",
                    hasName: true,
                    snippetName: "Python Main",
                    folderPath: "Code Snippets"
                ),
                ClipboardItem(
                    clipId: "code-2",
                    content: "git commit -m \"\"",
                    itemType: "snippet",
                    hasName: true,
                    snippetName: "Git Commit",
                    folderPath: "Code Snippets"
                )
            ]
        ),
        SnippetFolder(
            name: "Common Text",
            icon: "text.alignleft",
            isExpanded: false,
            snippets: []
        )
    ]
}
