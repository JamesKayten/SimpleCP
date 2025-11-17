import Foundation

// HTTP client for Python backend
@MainActor
class APIClient: ObservableObject {
    private let baseURL = "http://127.0.0.1:8000"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - History Endpoints

    func getHistory() async throws -> [ClipboardItem] {
        let url = URL(string: "\(baseURL)/api/history")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        let historyResponse = try JSONDecoder().decode(HistoryResponse.self, from: data)
        return historyResponse.history
    }

    func getHistoryFolders() async throws -> [HistoryFolder] {
        let url = URL(string: "\(baseURL)/api/history/folders")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        let foldersResponse = try JSONDecoder().decode(HistoryFoldersResponse.self, from: data)
        return foldersResponse.folders
    }

    func deleteHistoryItem(id: String) async throws {
        let url = URL(string: "\(baseURL)/api/history/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    func clearHistory() async throws {
        let url = URL(string: "\(baseURL)/api/history/clear")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Snippet Endpoints

    func getSnippets() async throws -> [String: [ClipboardItem]] {
        let url = URL(string: "\(baseURL)/api/snippets")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        let snippetsResponse = try JSONDecoder().decode(SnippetsResponse.self, from: data)
        return snippetsResponse.snippets
    }

    func createSnippet(request: CreateSnippetRequest) async throws {
        let url = URL(string: "\(baseURL)/api/snippets")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (_, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
    }

    func updateSnippet(folderId: String, itemId: String, request: UpdateSnippetRequest) async throws {
        let encodedFolder = folderId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folderId
        let url = URL(string: "\(baseURL)/api/snippets/\(encodedFolder)/\(itemId)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (_, response) = try await session.data(for: urlRequest)
        try validateResponse(response)
    }

    func deleteSnippet(folderId: String, itemId: String) async throws {
        let encodedFolder = folderId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folderId
        let url = URL(string: "\(baseURL)/api/snippets/\(encodedFolder)/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Folder Endpoints

    func createFolder(name: String) async throws {
        let url = URL(string: "\(baseURL)/api/folders")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CreateFolderRequest(name: name)
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    func renameFolder(oldName: String, newName: String) async throws {
        let url = URL(string: "\(baseURL)/api/folders/rename")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RenameFolderRequest(oldName: oldName, newName: newName)
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    func deleteFolder(name: String) async throws {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        let url = URL(string: "\(baseURL)/api/folders/\(encodedName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Operations

    func copyToClipboard(itemId: String) async throws {
        let url = URL(string: "\(baseURL)/api/clipboard/copy")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CopyToClipboardRequest(itemId: itemId)
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    func search(query: String) async throws -> SearchResults {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "\(baseURL)/api/search?query=\(encodedQuery)")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        return try JSONDecoder().decode(SearchResults.self, from: data)
    }

    func getHealth() async throws -> HealthStatus {
        let url = URL(string: "\(baseURL)/api/health")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        return try JSONDecoder().decode(HealthStatus.self, from: data)
    }

    // MARK: - Helper Methods

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
