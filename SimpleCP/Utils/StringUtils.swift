import Foundation

// String processing utilities
struct StringUtils {
    // Truncate string to max length with ellipsis
    static func truncate(_ string: String, maxLength: Int) -> String {
        if string.count <= maxLength {
            return string
        }
        let index = string.index(string.startIndex, offsetBy: maxLength - 3)
        return String(string[..<index]) + "..."
    }

    // Generate smart snippet name from content
    static func suggestSnippetName(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""

        // If first line is short, use it
        if firstLine.count <= 50 && !firstLine.isEmpty {
            return firstLine
        }

        // Otherwise truncate to first 50 chars
        return truncate(firstLine.isEmpty ? content : firstLine, maxLength: 50)
    }

    // Check if string contains code
    static func looksLikeCode(_ string: String) -> Bool {
        let codeIndicators = ["func ", "class ", "def ", "import ", "const ", "let ", "var ", "{", "}", "=>"]
        return codeIndicators.contains { string.contains($0) }
    }

    // Format tags as comma-separated string
    static func formatTags(_ tags: [String]) -> String {
        tags.joined(separator: ", ")
    }

    // Parse tags from comma-separated string
    static func parseTags(_ string: String) -> [String] {
        string.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // Highlight search query in text (for future use)
    static func highlightQuery(_ text: String, query: String) -> String {
        guard !query.isEmpty else { return text }
        return text.replacingOccurrences(
            of: query,
            with: "**\(query)**",
            options: .caseInsensitive
        )
    }
}
