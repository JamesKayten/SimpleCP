import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
}

@MainActor
class APIClient: ObservableObject {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "http://127.0.0.1:8000") {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    // MARK: - History Endpoints

    func getHistory() async throws -> [ClipboardItem] {
        let endpoint = "/api/clipboard/history"
        return try await get(endpoint: endpoint)
    }

    func getHistoryFolders() async throws -> [[ClipboardItem]] {
        let endpoint = "/api/clipboard/history/folders"
        return try await get(endpoint: endpoint)
    }

    func deleteHistoryItem(id: String) async throws {
        let endpoint = "/api/clipboard/history/\(id)"
        try await delete(endpoint: endpoint)
    }

    func clearHistory() async throws {
        let endpoint = "/api/clipboard/history/clear"
        try await post(endpoint: endpoint, body: EmptyRequest())
    }

    // MARK: - Snippet Endpoints

    func getSnippets() async throws -> [String: [ClipboardItem]] {
        let endpoint = "/api/snippets"
        return try await get(endpoint: endpoint)
    }

    func createSnippet(request: CreateSnippetRequest) async throws {
        let endpoint = "/api/snippets"
        try await post(endpoint: endpoint, body: request)
    }

    func updateSnippet(folderId: String, itemId: String, request: UpdateSnippetRequest) async throws {
        let endpoint = "/api/snippets/\(folderId)/\(itemId)"
        try await put(endpoint: endpoint, body: request)
    }

    func deleteSnippet(folderId: String, itemId: String) async throws {
        let endpoint = "/api/snippets/\(folderId)/\(itemId)"
        try await delete(endpoint: endpoint)
    }

    // MARK: - Folder Endpoints

    func createFolder(name: String) async throws {
        let endpoint = "/api/folders"
        let request = CreateFolderRequest(name: name)
        try await post(endpoint: endpoint, body: request)
    }

    func renameFolder(oldName: String, newName: String) async throws {
        let endpoint = "/api/folders/\(oldName)/rename"
        let request = RenameFolderRequest(newName: newName)
        try await post(endpoint: endpoint, body: request)
    }

    func deleteFolder(name: String) async throws {
        let endpoint = "/api/folders/\(name)"
        try await delete(endpoint: endpoint)
    }

    // MARK: - Operations

    func copyToClipboard(itemId: String) async throws {
        let endpoint = "/api/clipboard/copy/\(itemId)"
        try await post(endpoint: endpoint, body: EmptyRequest())
    }

    func search(query: String) async throws -> SearchResults {
        let endpoint = "/api/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        return try await get(endpoint: endpoint)
    }

    func getHealth() async throws -> HealthStatus {
        let endpoint = "/api/health"
        return try await get(endpoint: endpoint)
    }

    // MARK: - HTTP Methods

    private func get<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func post<T: Encodable>(endpoint: String, body: T) async throws {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func put<T: Encodable>(endpoint: String, body: T) async throws {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func delete(endpoint: String) async throws {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Empty Request

struct EmptyRequest: Codable {}
