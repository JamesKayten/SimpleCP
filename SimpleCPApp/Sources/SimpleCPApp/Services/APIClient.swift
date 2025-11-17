//
//  APIClient.swift
//  SimpleCPApp
//
//  HTTP client for Python FastAPI backend
//

import Foundation

/// API client for communicating with Python backend
@MainActor
class APIClient: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var lastError: String?

    private var baseURL: String
    private let session: URLSession

    init(baseURL: String = "http://127.0.0.1:8000") {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    // MARK: - Configuration Discovery
    func fetchConfig() async throws -> APIConfig {
        let url = URL(string: "\(baseURL)/config")!
        let (data, _) = try await session.data(from: url)
        let config = try JSONDecoder().decode(APIConfig.self, from: data)
        // Update base URL from config
        self.baseURL = "http://\(config.host):\(config.port)"
        return config
    }

    func checkHealth() async throws -> HealthResponse {
        let url = URL(string: "\(baseURL)/health")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }

    // MARK: - History Operations
    func getHistory() async throws -> [ClipboardItem] {
        try await get(path: "/api/v1/history")
    }

    func getRecentHistory() async throws -> [ClipboardItem] {
        try await get(path: "/api/v1/history/recent")
    }

    func getHistoryFolders() async throws -> [HistoryFolder] {
        try await get(path: "/api/v1/history/folders")
    }

    func deleteHistoryItem(id: String) async throws {
        try await delete(path: "/api/v1/history/\(id)")
    }

    func clearHistory() async throws {
        try await delete(path: "/api/v1/history")
    }

    // MARK: - Snippet Operations
    func getSnippets() async throws -> [String: [ClipboardItem]] {
        try await get(path: "/api/v1/snippets")
    }

    func getSnippetFolders() async throws -> [String] {
        try await get(path: "/api/v1/snippets/folders")
    }

    func createSnippet(request: CreateSnippetRequest) async throws -> ClipboardItem {
        try await post(path: "/api/v1/snippets", body: request)
    }

    func updateSnippet(folder: String, id: String, request: UpdateSnippetRequest) async throws {
        try await put(path: "/api/v1/snippets/\(folder)/\(id)", body: request)
    }

    func deleteSnippet(folder: String, id: String) async throws {
        try await delete(path: "/api/v1/snippets/\(folder)/\(id)")
    }

    func moveSnippet(folder: String, id: String, request: MoveSnippetRequest) async throws {
        try await put(path: "/api/v1/snippets/\(folder)/\(id)/move", body: request)
    }

    // MARK: - Folder Operations
    func createFolder(name: String) async throws {
        let request = CreateFolderRequest(folderName: name)
        try await post(path: "/api/v1/snippets/folders", body: request)
    }

    func renameFolder(oldName: String, newName: String) async throws {
        let request = RenameFolderRequest(newName: newName)
        try await put(path: "/api/v1/snippets/folders/\(oldName)", body: request)
    }

    func deleteFolder(name: String) async throws {
        try await delete(path: "/api/v1/snippets/folders/\(name)")
    }

    // MARK: - Clipboard Operations
    func copyToClipboard(itemId: String) async throws {
        let request = CopyRequest(clipId: itemId)
        try await post(path: "/api/v1/clipboard/copy", body: request)
    }

    // MARK: - Search
    func search(query: String) async throws -> SearchResults {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await get(path: "/api/v1/search?q=\(encodedQuery)")
    }

    // MARK: - HTTP Helpers
    private func get<T: Decodable>(path: String) async throws -> T {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        try checkResponse(response)

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Encodable, R: Decodable>(path: String, body: T) async throws -> R {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try checkResponse(response)

        return try JSONDecoder().decode(R.self, from: data)
    }

    private func post<T: Encodable>(path: String, body: T) async throws {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await session.data(for: request)
        try checkResponse(response)
    }

    private func put<T: Encodable>(path: String, body: T) async throws {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await session.data(for: request)
        try checkResponse(response)
    }

    private func delete(path: String) async throws {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)
        try checkResponse(response)
    }

    private func checkResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
