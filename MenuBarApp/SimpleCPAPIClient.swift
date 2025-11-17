import Foundation

class SimpleCPAPIClient {
    let baseURL: String

    init(baseURL: String = "http://127.0.0.1:8000") {
        self.baseURL = baseURL
    }

    // MARK: - History Operations

    func getHistory(limit: Int? = nil) async throws -> [ClipboardItem] {
        var urlString = "\(baseURL)/api/history"
        if let limit = limit {
            urlString += "?limit=\(limit)"
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ClipboardItem].self, from: data)
    }

    func getRecentHistory() async throws -> [ClipboardItem] {
        guard let url = URL(string: "\(baseURL)/api/history/recent") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ClipboardItem].self, from: data)
    }

    func deleteHistoryItem(clipId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/history/\(clipId)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }

    func clearHistory() async throws {
        guard let url = URL(string: "\(baseURL)/api/history") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }

    // MARK: - Snippet Operations

    func getSnippets() async throws -> [SnippetFolder] {
        guard let url = URL(string: "\(baseURL)/api/snippets") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([SnippetFolder].self, from: data)
    }

    func createSnippet(content: String, name: String, folder: String, tags: [String]? = nil) async throws -> ClipboardItem {
        guard let url = URL(string: "\(baseURL)/api/snippets") else {
            throw APIError.invalidURL
        }

        let body: [String: Any] = [
            "content": content,
            "name": name,
            "folder": folder,
            "tags": tags ?? []
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ClipboardItem.self, from: data)
    }

    // MARK: - Clipboard Operations

    func copyToClipboard(clipId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/clipboard/copy") else {
            throw APIError.invalidURL
        }

        let body: [String: String] = ["clip_id": clipId]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }

    // MARK: - Search Operations

    func search(query: String) async throws -> SearchResults {
        guard var components = URLComponents(string: "\(baseURL)/api/search") else {
            throw APIError.invalidURL
        }

        components.queryItems = [URLQueryItem(name: "q", value: query)]

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(SearchResults.self, from: data)
    }

    func advancedSearch(
        query: String? = nil,
        searchType: String = "fuzzy",
        contentTypes: [String]? = nil,
        sourceApps: [String]? = nil,
        sortBy: String? = nil
    ) async throws -> SearchResults {
        guard var components = URLComponents(string: "\(baseURL)/api/search/advanced") else {
            throw APIError.invalidURL
        }

        var queryItems: [URLQueryItem] = []

        if let query = query {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }

        queryItems.append(URLQueryItem(name: "search_type", value: searchType))

        if let contentTypes = contentTypes {
            queryItems.append(URLQueryItem(name: "content_types", value: contentTypes.joined(separator: ",")))
        }

        if let sourceApps = sourceApps {
            queryItems.append(URLQueryItem(name: "source_apps", value: sourceApps.joined(separator: ",")))
        }

        if let sortBy = sortBy {
            queryItems.append(URLQueryItem(name: "sort_by", value: sortBy))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(SearchResults.self, from: data)
    }

    // MARK: - Analytics Operations

    func getStats() async throws -> Stats {
        guard let url = URL(string: "\(baseURL)/api/stats") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Stats.self, from: data)
    }

    func getAnalyticsSummary(period: String = "week") async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/api/analytics/summary?period=\(period)") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingFailed
        }

        return json
    }

    // MARK: - Settings Operations

    func getSettings() async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/api/settings") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingFailed
        }

        return json
    }

    func updateSettingsSection(section: String, updates: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/api/settings/\(section)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: updates)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }

    // MARK: - Export Operations

    func exportHistory(format: String = "json") async throws -> Data {
        guard let url = URL(string: "\(baseURL)/api/export/history?format=\(format)") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

// MARK: - Models

struct ClipboardItem: Codable, Identifiable {
    let clipId: String
    let content: String
    let timestamp: String
    let contentType: String
    let sourceApp: String?
    let displayString: String
    let snippetName: String?
    let folderPath: String?
    let tags: [String]?

    var id: String { clipId }

    enum CodingKeys: String, CodingKey {
        case clipId = "clip_id"
        case content
        case timestamp
        case contentType = "content_type"
        case sourceApp = "source_app"
        case displayString = "display_string"
        case snippetName = "snippet_name"
        case folderPath = "folder_path"
        case tags
    }
}

struct SnippetFolder: Codable {
    let folderName: String
    let snippets: [ClipboardItem]

    enum CodingKeys: String, CodingKey {
        case folderName = "folder_name"
        case snippets
    }
}

struct SearchResults: Codable {
    let history: [ClipboardItem]
    let snippets: [ClipboardItem]
}

struct Stats: Codable {
    let historyCount: Int
    let snippetCount: Int
    let folderCount: Int
    let maxHistory: Int

    enum CodingKeys: String, CodingKey {
        case historyCount = "history_count"
        case snippetCount = "snippet_count"
        case folderCount = "folder_count"
        case maxHistory = "max_history"
    }
}

// MARK: - Errors

enum APIError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
}
