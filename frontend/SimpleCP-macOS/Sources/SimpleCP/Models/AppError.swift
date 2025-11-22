//
//  AppError.swift
//  SimpleCP
//
//  Created by SimpleCP
//

import Foundation

enum AppError: LocalizedError {
    case clipboardAccessDenied
    case storageFailure(String)
    case importFailure(String)
    case exportFailure(String)
    case invalidData
    case encodingFailure(String)
    case decodingFailure(String)
    case invalidURL
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .clipboardAccessDenied:
            return "Unable to access clipboard"
        case .storageFailure(let key):
            return "Failed to save \(key)"
        case .importFailure(let reason):
            return "Import failed: \(reason)"
        case .exportFailure(let reason):
            return "Export failed: \(reason)"
        case .invalidData:
            return "Invalid data format"
        case .encodingFailure(let what):
            return "Failed to encode \(what)"
        case .decodingFailure(let what):
            return "Failed to decode \(what)"
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let reason):
            return "Network error: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .clipboardAccessDenied:
            return "Open System Settings → Privacy & Security → Accessibility and enable SimpleCP."
        case .storageFailure:
            return "Try restarting the app or clearing some disk space."
        case .importFailure, .exportFailure:
            return "Check the file format and try again."
        case .invalidData:
            return "The file may be corrupted. Try exporting your data again from the source."
        case .encodingFailure, .decodingFailure:
            return "This might be a temporary issue. Try again or restart the app."
        case .invalidURL:
            return "Check your API configuration."
        case .networkError:
            return "Check your internet connection and make sure the API server is running."
        }
    }

    var failureReason: String? {
        switch self {
        case .clipboardAccessDenied:
            return "SimpleCP needs accessibility permissions to monitor your clipboard."
        case .storageFailure:
            return "Unable to write data to storage."
        case .importFailure:
            return "The import file could not be processed."
        case .exportFailure:
            return "Unable to write export file."
        case .invalidData:
            return "The data structure is not recognized."
        case .encodingFailure:
            return "Unable to convert data to storage format."
        case .decodingFailure:
            return "Unable to read data from storage."
        case .invalidURL:
            return "The API URL is malformed."
        case .networkError:
            return "Unable to communicate with the API server."
        }
    }
}
