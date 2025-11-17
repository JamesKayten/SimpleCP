import Foundation

// Folder organization for snippets
struct SnippetFolder: Identifiable, Equatable {
    let id = UUID()
    let name: String
    var items: [ClipboardItem]
    var isExpanded: Bool = true

    static func == (lhs: SnippetFolder, rhs: SnippetFolder) -> Bool {
        lhs.name == rhs.name
    }
}
