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
    case invalidRequest(String)

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
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        }
    }
}

class APIClient {
    static let shared = APIClient()

    let baseURL: String
    let logger = Logger(subsystem: "com.simplecp.app", category: "api")

    // Retry configuration
    let maxRetryAttempts: Int = 3
    let initialRetryDelay: TimeInterval = 1.0
    let maxRetryDelay: TimeInterval = 8.0
    let retryMultiplier: Double = 2.0

    init(baseURL: String? = nil) {
        if let baseURL = baseURL {
            self.baseURL = baseURL
        } else {
            // Use configurable host and port with sensible defaults
            let host = UserDefaults.standard.string(forKey: "apiHost") ?? "localhost"
            let port = UserDefaults.standard.integer(forKey: "apiPort")
            let apiPort = port > 0 ? port : 8000
            self.baseURL = "http://\(host):\(apiPort)"
        }
    }

    // MARK: - Retry Logic

    /// Execute a network request with exponential backoff retry logic
    func executeWithRetry<T>(
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
    func shouldRetryError(_ error: Error, customPredicate: ((Error) -> Bool)? = nil) -> Bool {
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
            case .invalidURL, .decodingError, .invalidRequest:
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
    func calculateRetryDelay(attempt: Int) -> TimeInterval {
        let baseDelay = initialRetryDelay * pow(retryMultiplier, Double(attempt - 1))
        let delayWithCap = min(baseDelay, maxRetryDelay)

        // Add jitter to prevent thundering herd
        let jitter = Double.random(in: 0.8...1.2)
        return delayWithCap * jitter
    }
}
