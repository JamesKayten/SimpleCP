//
//  APIClient+Snippets.swift
//  SimpleCP
//
//  Snippet operations extension for APIClient
//

import Foundation

extension APIClient {
    // MARK: - Snippet Operations

    func createSnippet(name: String, content: String, folder: String, tags: [String], clipId: String? = nil) async throws {
        return try await executeWithRetry(operation: "Create snippet '\(name)' in folder '\(folder)'") {
            let urlString = "\(self.baseURL)/api/snippets"

            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("keep-alive", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30.0  // Increased timeout for potentially large snippets

            // Build request body - only include clip_id if provided
            var body: [String: Any] = [
                "name": name,
                "content": content,
                "folder": folder,
                "tags": tags
            ]
            
            // Only include clip_id if it exists (from clipboard history)
            if let clipId = clipId {
                body["clip_id"] = clipId
                self.logger.info("📡 API: Creating snippet '\(name)' in folder '\(folder)' with clip_id '\(clipId)'")
            } else {
                self.logger.info("📡 API: Creating snippet '\(name)' in folder '\(folder)' (no clip_id - direct creation)")
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

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
            request.setValue("keep-alive", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30.0  // Increased timeout for potentially large snippets

            var body: [String: Any] = [
                "clip_id": clipId  // Backend requires clip_id in the body
            ]
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
            request.timeoutInterval = 30.0  // Increased timeout

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
            } catch {
                self.logger.error("❌ Network error: \(error.localizedDescription)")
                throw APIError.networkError(error)
            }
        }
    }
}
