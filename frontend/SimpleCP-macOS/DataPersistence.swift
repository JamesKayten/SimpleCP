//
//  DataPersistence.swift
//  SimpleCP
//
//  Handles file-based data persistence for large data sets
//  Replaces UserDefaults for clipboard history and snippets to avoid size limits
//

import Foundation
import os.log

/// Manages file-based persistence for app data
actor DataPersistenceManager {
    static let shared = DataPersistenceManager()
    
    private let logger = Logger(subsystem: "com.simplecp.app", category: "persistence")
    private let fileManager = FileManager.default
    
    /// App's data directory in Application Support
    private var dataDirectory: URL {
        get throws {
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let appDirectory = appSupport.appendingPathComponent("SimpleCP", isDirectory: true)
            
            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: appDirectory.path) {
                try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
            }
            
            return appDirectory
        }
    }
    
    // MARK: - Generic Persistence
    
    /// Save Codable data to file
    func save<T: Codable>(_ data: T, filename: String) async throws {
        let directory = try dataDirectory
        let fileURL = directory.appendingPathComponent(filename)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: fileURL, options: .atomic)
        
        logger.info("💾 Saved \(filename) (\(jsonData.count) bytes)")
    }
    
    /// Load Codable data from file
    func load<T: Codable>(filename: String, as type: T.Type) async throws -> T {
        let directory = try dataDirectory
        let fileURL = directory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.info("📂 File not found: \(filename), will use defaults")
            throw PersistenceError.fileNotFound
        }
        
        let data = try Data(contentsOf: fileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decoded = try decoder.decode(type, from: data)
        logger.info("📂 Loaded \(filename) (\(data.count) bytes)")
        
        return decoded
    }
    
    /// Delete a file
    func delete(filename: String) async throws {
        let directory = try dataDirectory
        let fileURL = directory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
            logger.info("🗑️ Deleted \(filename)")
        }
    }
    
    /// Check if file exists
    func fileExists(filename: String) async -> Bool {
        guard let directory = try? dataDirectory else { return false }
        let fileURL = directory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Get file size in bytes
    func fileSize(filename: String) async -> Int? {
        guard let directory = try? dataDirectory else { return nil }
        let fileURL = directory.appendingPathComponent(filename)
        
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path) else {
            return nil
        }
        
        return attributes[.size] as? Int
    }
    
    // MARK: - Migration from UserDefaults
    
    /// Migrate data from UserDefaults to file-based storage
    func migrateFromUserDefaults<T: Codable>(key: String, filename: String, as type: T.Type) async throws -> T? {
        let userDefaults = UserDefaults.standard
        
        // Check if data exists in UserDefaults
        guard let data = userDefaults.data(forKey: key) else {
            logger.info("🔄 No data to migrate from UserDefaults key: \(key)")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(type, from: data)
            
            // Save to file
            try await save(decoded, filename: filename)
            
            // Remove from UserDefaults to free space
            userDefaults.removeObject(forKey: key)
            
            logger.info("✅ Migrated \(key) from UserDefaults to \(filename)")
            return decoded
        } catch {
            logger.error("❌ Failed to migrate \(key): \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Errors

enum PersistenceError: LocalizedError {
    case fileNotFound
    case directoryCreationFailed
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Data file not found"
        case .directoryCreationFailed:
            return "Could not create data directory"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}
