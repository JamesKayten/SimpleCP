import Foundation

enum StringUtils {
    static func truncate(_ string: String, length: Int, trailing: String = "...") -> String {
        if string.count > length {
            return String(string.prefix(length)) + trailing
        }
        return string
    }

    static func firstLine(_ string: String) -> String {
        string.components(separatedBy: .newlines).first ?? string
    }

    static func preview(_ string: String, maxLength: Int = 100) -> String {
        let firstLine = firstLine(string)
        return truncate(firstLine, length: maxLength)
    }

    static func sanitize(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func parseTags(_ tagsString: String) -> [String] {
        tagsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
