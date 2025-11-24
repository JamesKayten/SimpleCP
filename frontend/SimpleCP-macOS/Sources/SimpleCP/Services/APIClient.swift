//
//  APIClient.swift
//  SimpleCP
//
//  API client for backend communication
//

import Foundation
import os.log

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

class APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let logger = Logger(subsystem: "com.simplecp.app", category: "api")

    // Retry configuration
    private let maxRetryAttempts: Int = 3
    private let initialRetryDelay: TimeInterval = 1.0
    private let maxRetryDelay: TimeInterval = 8.0
    private let retryMultiplier: Double = 2.0

    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
    }

    // MARK: - Retry Logic

    /// Execute a network request with exponential backoff retry logic
    private func executeWithRetry<T>(
        operation: String,
        maxAttempts: Int? = nil,
        retryableErrorPredicate: ((Error) -> Bool)? = nil,
        block: @escaping () async throws -> T
    ) async throws -> T {
        let attempts = maxAttempts ?? maxRetryAttempts
        var lastError: Error?

        for attempt in 1...attempts {
            do {
                let result = try await block()

                if attempt > 1 {
                    logger.info("✅ \(operation) succeeded on attempt \(attempt)")
                }

                return result
            } catch {
                lastError = error

                // Check if this error type should be retried
                let shouldRetry = shouldRetryError(error, customPredicate: retryableErrorPredicate)

                if attempt == attempts || !shouldRetry {
                    if !shouldRetry {
                        logger.info("⚠️ \(operation) failed with non-retryable error: \(error.localizedDescription)")
                    } else {
                        logger.error("❌ \(operation) failed after \(attempts) attempts")
                    }
                    throw error
                }

                // Calculate delay with exponential backoff
                let delay = calculateRetryDelay(attempt: attempt)
                logger.warning("⏱️ \(operation) failed on attempt \(attempt), retrying in \(String(format: "%.1f", delay))s... Error: \(error.localizedDescription)")

                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // Should never reach here, but throw the last error as fallback
        throw lastError ?? APIError.networkError(NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown retry error"]))
    }

    /// Determine if an error should trigger a retry
    private func shouldRetryError(_ error: Error, customPredicate: ((Error) -> Bool)? = nil) -> Bool {
        // Use custom predicate if provided
        if let customPredicate = customPredicate {
            return customPredicate(error)
        }

        // Default retry logic
        switch error {
        case let apiError as APIError:
            switch apiError {
            case .networkError:
                return true // Always retry network errors
            case .httpError(let statusCode, _):
                // Retry on server errors (5xx) and some client errors
                return statusCode >= 500 || statusCode == 408 || statusCode == 429
            case .invalidResponse:
                return true // Might be temporary server issue
            case .invalidURL, .decodingError:
                return false // Don't retry client-side errors
            }
        case let urlError as URLError:
            // Retry specific URL error cases
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut,
                 .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

    /// Calculate retry delay using exponential backoff with jitter
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        let baseDelay = initialRetryDelay * pow(retryMultiplier, Double(attempt - 1))
        let delayWithCap = min(baseDelay, maxRetryDelay)

        // Add jitter to prevent thundering herd
        let jitter = Double.random(in: 0.8...1.2)
        return delayWithCap * jitter
    }

    // MARK: - Folder Operations

    func fetchFolderNames() async throws -> [String] {
        return try await executeWithRetry(operation: "Fetch folder names") {
            let url = URL(string: "\(self.baseURL)/api/folders")!

            self.logger.info("📡 API: Fetching folder names from backend")

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: "Failed to fetch folders")
            }

            let folderNames = try JSONDecoder().decode([String].self, from: data)
            self.logger.info("✅ Fetched \(folderNames.count) folder names from backend")
            return folderNames
        }
    }

    func renameFolder(oldName: String, newName: String) async throws {
        return try await executeWithRetry(
            operation: "Rename folder '\(oldName)' to '\(newName)'",
            maxAttempts: 5 // More attempts for critical folder operations
        ) {
            let urlString = "\(self.baseURL)/api/folders/\(oldName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? oldName)"

            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0 // Longer timeout for folder operations

            let body = ["new_name": newName]
            request.httpBody = try JSONEncoder().encode(body)

            self.logger.info("📡 API: Renaming folder '\(oldName)' to '\(newName)'")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    self.logger.error("❌ API Error: \(httpResponse.statusCode) - \(errorMessage)")
                    throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
                }

                self.logger.info("✅ Folder renamed successfully")
            } catch let error as APIError {
                throw error
            } catch {
                self.logger.error("❌ Network error: \(error.localizedDescription)")
                throw APIError.networkError(error)
            }
        }
    }

    func createFolder(name: String) async throws {
        return try await executeWithRetry(operation: "Create folder '\(name)'") {
            let urlString = "\(self.baseURL)/api/folders"

            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0

            let body = ["folder_name": name]
            request.httpBody = try JSONEncoder().encode(body)

            self.logger.info("📡 API: Creating folder '\(name)'")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    self.logger.error("❌ API Error: \(httpResponse.statusCode) - \(errorMessage)")
                    throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
                }

                self.logger.info("✅ Folder created successfully")
            } catch let error as APIError {
                throw error
            } catch {
                self.logger.error("❌ Network error: \(error.localizedDescription)")
                throw APIError.networkError(error)
            }
        }
    }

    func deleteFolder(name: String) async throws {
        return try await executeWithRetry(operation: "Delete folder '\(name)'") {
            let urlString = "\(self.baseURL)/api/folders/\(name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name)"

            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.timeoutInterval = 10.0

            self.logger.info("📡 API: Deleting folder '\(name)'")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    self.logger.error("❌ API Error: \(httpResponse.statusCode) - \(errorMessage)")
                    throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
                }

                self.logger.info("✅ Folder deleted successfully")
            } catch let error as APIError {
                throw error
            } catch {
                self.logger.error("❌ Network error: \(error.localizedDescription)")
                throw APIError.networkError(error)
            }
        }
    }

    // MARK: - Snippet Operations

    func createSnippet(name: String, content: String, folder: String, tags: [String]) async throws {
        return try await executeWithRetry(operation: "Create snippet '\(name)' in folder '\(folder)'") {
            let urlString = "\(self.baseURL)/api/snippets"

            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0

            let body: [String: Any] = [
                "name": name,
                "content": content,
                "folder": folder,
                "tags": tags
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            self.logger.info("📡 API: Creating snippet '\(name)' in folder '\(folder)'")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    self.logger.error("❌ API Error: \(httpResponse.statusCode) - \(errorMessage)")
                    throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
                }

                self.logger.info("✅ Snippet created successfully")
            } catch let error as APIError {
                throw error
            } catch {
                self.logger.error("❌ Network error: \(error.localizedDescription)")
                throw APIError.networkError(error)
            }
        }
    }

    func updateSnippet(folderName: String, clipId: String, content: String?, name: String?, tags: [String]?) async throws {
        return try await executeWithRetry(operation: "Update snippet in folder '\(folderName)'") {
            let urlString = "\(self.baseURL)/api/snippets/\(folderName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folderName)/\(clipId)"

            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0

            var body: [String: Any] = [:]
            if let content = content { body["content"] = content }
            if let name = name { body["name"] = name }
            if let tags = tags { body["tags"] = tags }

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            self.logger.info("📡 API: Updating snippet in folder '\(folderName)'")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    self.logger.error("❌ API Error: \(httpResponse.statusCode) - \(errorMessage)")
                    throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
                }

                self.logger.info("✅ Snippet updated successfully")
            } catch let error as APIError {
                throw error
            } catch {
                self.logger.error("❌ Network error: \(error.localizedDescription)")
                throw APIError.networkError(error)
            }
        }
    }

    func deleteSnippet(folderName: String, clipId: String) async throws {
        return try await executeWithRetry(operation: "Delete snippet from folder '\(folderName)'") {
            let urlString = "\(self.baseURL)/api/snippets/\(folderName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folderName)/\(clipId)"

            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.timeoutInterval = 10.0

            self.logger.info("📡 API: Deleting snippet from folder '\(folderName)'")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    self.logger.error("❌ API Error: \(httpResponse.statusCode) - \(errorMessage)")
                    throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
                }

                self.logger.info("✅ Snippet deleted successfully")
            } catch let error as APIError {
                throw error
            } catch {
                self.logger.error("❌ Network error: \(error.localizedDescription)")
                throw APIError.networkError(error)
            }
        }
    }
}
