//
//  APIClient+Folders.swift
//  SimpleCP
//
//  Folder operations extension for APIClient
//

import Foundation

extension APIClient {
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
            } catch {
                self.logger.error("❌ Network error: \(error.localizedDescription)")
                throw APIError.networkError(error)
            }
        }
    }
}
