import Foundation

class APIClient: ObservableObject {
    private let baseURL = "http://127.0.0.1:8000"
    private let session = URLSession.shared

    // MARK: - History Endpoints
    func getHistory(limit: Int? = nil) async throws -> [ClipboardItem] {
        var url = URL(string: "\(baseURL)/api/history")!
        if let limit = limit {
            url.appendQueryItem(name: "limit", value: "\(limit)")
        }

        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([ClipboardItem].self, from: data)
    }

    func getHistoryFolders() async throws -> [HistoryFolder] {
        let url = URL(string: "\(baseURL)/api/history/folders")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([HistoryFolder].self, from: data)
    }

    func clearHistory() async throws {
        let url = URL(string: "\(baseURL)/api/history")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, _) = try await session.data(for: request)
    }

    // MARK: - Snippet Endpoints
    func getAllSnippets() async throws -> [SnippetFolder] {
        let url = URL(string: "\(baseURL)/api/snippets")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([SnippetFolder].self, from: data)
    }

    func getFolderSnippets(folder: String) async throws -> [ClipboardItem] {
        let url = URL(string: "\(baseURL)/api/snippets/\(folder)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([ClipboardItem].self, from: data)
    }

    func createSnippet(
        clipId: String? = nil,
        content: String? = nil,
        name: String,
        folder: String,
        tags: [String] = []
    ) async throws -> ClipboardItem {
        let url = URL(string: "\(baseURL)/api/snippets")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "clip_id": clipId,
            "content": content,
            "name": name,
            "folder": folder,
            "tags": tags
        ] as [String: Any?]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ClipboardItem.self, from: data)
    }

    func updateSnippet(
        folder: String,
        clipId: String,
        content: String? = nil,
        name: String? = nil,
        tags: [String]? = nil
    ) async throws {
        let encodedFolder = folder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folder
        let url = URL(string: "\(baseURL)/api/snippets/\(encodedFolder)/\(clipId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any?] = [:]
        if let content = content { body["content"] = content }
        if let name = name { body["name"] = name }
        if let tags = tags { body["tags"] = tags }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, _) = try await session.data(for: request)
    }

    func deleteSnippet(folder: String, clipId: String) async throws {
        let encodedFolder = folder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folder
        let url = URL(string: "\(baseURL)/api/snippets/\(encodedFolder)/\(clipId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, _) = try await session.data(for: request)
    }

    func moveSnippet(folder: String, clipId: String, toFolder: String) async throws {
        let encodedFolder = folder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folder
        let url = URL(string: "\(baseURL)/api/snippets/\(encodedFolder)/\(clipId)/move")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["to_folder": toFolder]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, _) = try await session.data(for: request)
    }

    // MARK: - Folder Endpoints
    func createFolder(name: String) async throws {
        let url = URL(string: "\(baseURL)/api/folders")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["folder_name": name]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, _) = try await session.data(for: request)
    }

    func renameFolder(oldName: String, newName: String) async throws {
        let encodedName = oldName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? oldName
        let url = URL(string: "\(baseURL)/api/folders/\(encodedName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["new_name": newName]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, _) = try await session.data(for: request)
    }

    func deleteFolder(name: String) async throws {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        let url = URL(string: "\(baseURL)/api/folders/\(encodedName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, _) = try await session.data(for: request)
    }

    func deleteHistoryItem(clipId: String) async throws {
        let url = URL(string: "\(baseURL)/api/history/\(clipId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, _) = try await session.data(for: request)
    }

    // MARK: - Clipboard Operations
    func copyToClipboard(clipId: String) async throws {
        let url = URL(string: "\(baseURL)/api/copy")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["clip_id": clipId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, _) = try await session.data(for: request)
    }

    // MARK: - Search
    func search(query: String) async throws -> SearchResults {
        var url = URL(string: "\(baseURL)/api/search")!
        url.appendQueryItem(name: "q", value: query)

        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(SearchResults.self, from: data)
    }

    // MARK: - Status
    func getStatus() async throws -> [String: Any] {
        let url = URL(string: "\(baseURL)/api/status")!
        let (data, _) = try await session.data(from: url)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json ?? [:]
    }
}

// Helper extension for URL query items
extension URL {
    mutating func appendQueryItem(name: String, value: String) {
        guard var urlComponents = URLComponents(string: absoluteString) else {
            return
        }

        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        urlComponents.queryItems = queryItems

        if let newURL = urlComponents.url {
            self = newURL
        }
    }
}